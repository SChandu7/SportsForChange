import os
import json
import boto3
from datetime import datetime

from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Count

import firebase_admin
from firebase_admin import credentials, messaging

from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import SFCUser, SportsDailyActivity, SportsDailyActivityImages, SportsNotificationToken
from .serializers import SportsDailyActivitySerializer, SportsNotificationTokenSerializer


_FIREBASE_CRED = os.path.join(
    '/home/ubuntu/djangobackend/firstdemoapp2',
    'sportsforchangeproject-firebase-adminsdk-8u6av-c929095979.json',
)
if not firebase_admin._apps and os.path.exists(_FIREBASE_CRED):
    firebase_admin.initialize_app(credentials.Certificate(_FIREBASE_CRED))


def _s3():
    return boto3.client(
        's3',
        region_name=settings.AWS_S3_REGION_NAME,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    )


# ── Auth ───────────────────────────────────────────────────────────────────────

@csrf_exempt
def sfc_login(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Only POST allowed'}, status=405)
    try:
        if request.content_type and 'application/json' in request.content_type:
            data     = json.loads(request.body)
            username = data.get('username', '').strip()
            password = data.get('password', '')
        else:
            username = (request.POST.get('username') or '').strip()
            password = (request.POST.get('password') or '')
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({'status': 'error', 'message': 'Invalid request body'}, status=400)

    if not username or not password:
        return JsonResponse({'status': 'error', 'message': 'Username and password required'}, status=400)

    user = SFCUser.objects.filter(username=username, password=password).first()
    if user:
        return JsonResponse({'status': 'success', 'message': 'Login successful'}, status=200)
    return JsonResponse({'status': 'error', 'message': 'Invalid credentials'}, status=401)


@csrf_exempt
def sfc_signup(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Only POST allowed'}, status=405)

    username = (request.POST.get('username') or '').strip()
    password = (request.POST.get('password') or '').strip()

    if not username or not password:
        return JsonResponse({'status': 'error', 'message': 'username and password required'}, status=400)

    if SFCUser.objects.filter(username=username).exists():
        return JsonResponse({'status': 'error', 'message': 'userAlreadyExists'}, status=400)

    SFCUser.objects.create(username=username, password=password)
    return JsonResponse({'status': 'success', 'message': 'Signup successful'}, status=200)


@csrf_exempt
def upload_file_to_s3(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    uploaded = request.FILES.get('file')
    if not uploaded:
        return JsonResponse({'error': 'No file provided'}, status=400)

    key = f"profileimages/{uploaded.name}"
    try:
        s3 = _s3()
        s3.upload_fileobj(
            uploaded,
            settings.AWS_STORAGE_BUCKET_NAME,
            key,
            ExtraArgs={'ContentType': uploaded.content_type},
        )
        url = (
            f"https://{settings.AWS_STORAGE_BUCKET_NAME}"
            f".s3.{settings.AWS_S3_REGION_NAME}.amazonaws.com/{key}"
        )
        return JsonResponse({'url': url, 'status': 'success'}, status=200)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ── Activities ─────────────────────────────────────────────────────────────────

class PostSportsDailyActivityView(APIView):
    def post(self, request, format=None):
        serializer = SportsDailyActivitySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        activity = serializer.save()

        images = request.FILES.getlist('images')
        if images:
            s3 = _s3()
            for img in images:
                key = f"sportsactivityimages/{activity.id}_{img.name}"
                s3.upload_fileobj(
                    img,
                    settings.AWS_STORAGE_BUCKET_NAME,
                    key,
                    ExtraArgs={'ContentType': img.content_type},
                )
                url = (
                    f"https://{settings.AWS_STORAGE_BUCKET_NAME}"
                    f".s3.{settings.AWS_S3_REGION_NAME}.amazonaws.com/{key}"
                )
                SportsDailyActivityImages.objects.create(activity=activity, image_url=url)

        return Response(SportsDailyActivitySerializer(activity).data, status=status.HTTP_201_CREATED)


class GetSportsDailyActivityView(APIView):
    def get(self, request, format=None):
        qs = SportsDailyActivity.objects.all()

        school  = request.query_params.get('school')
        pt_name = request.query_params.get('pt_name')

        if school:
            qs = qs.filter(school=school)
        if pt_name:
            qs = qs.filter(pt_name=pt_name)

        return Response(SportsDailyActivitySerializer(qs, many=True).data, status=status.HTTP_200_OK)


@api_view(['GET'])
def sports_stats(request):
    now       = datetime.now()
    today_str = f"{now.month}/{now.day}/{now.year}"

    total       = SportsDailyActivity.objects.count()
    today_count = SportsDailyActivity.objects.filter(date=today_str).count()

    per_school = list(
        SportsDailyActivity.objects
        .values('school').annotate(count=Count('id')).order_by('school')
    )
    per_pt = list(
        SportsDailyActivity.objects
        .values('pt_name').annotate(count=Count('id')).order_by('pt_name')
    )

    return JsonResponse({
        'total_activities': total,
        'today_count':      today_count,
        'per_school':       per_school,
        'per_pt':           per_pt,
    })


# ── Push Notifications ─────────────────────────────────────────────────────────

class PostSportsNotificationTokenView(APIView):
    def post(self, request):
        serializer = SportsNotificationTokenSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        SportsNotificationToken.objects.update_or_create(
            username=serializer.validated_data['username'],
            defaults={'device_token': serializer.validated_data['device_token']},
        )
        return Response({'message': 'Token saved'}, status=status.HTTP_201_CREATED)


class GetSportsNotificationTokensView(APIView):
    def get(self, request):
        tokens = list(SportsNotificationToken.objects.values_list('device_token', flat=True))
        return Response({'tokens': tokens})


class SendSportsActivityNotificationToAll(APIView):
    def post(self, request):
        title  = request.data.get('title', '')
        body   = request.data.get('body', '')
        tokens = list(SportsNotificationToken.objects.values_list('device_token', flat=True))

        if not tokens:
            return Response({'message': 'No tokens registered.'}, status=200)

        if not firebase_admin._apps:
            return Response({'error': 'Firebase not initialised on server.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        msg    = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            tokens=tokens,
        )
        result = messaging.send_multicast(msg)
        return Response({'sent': result.success_count, 'failed': result.failure_count}, status=200)
