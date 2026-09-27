from rest_framework import serializers
from .models import SportsDailyActivity, SportsDailyActivityImages, SportsNotificationToken


class SportsDailyActivityImagesSerializer(serializers.ModelSerializer):
    class Meta:
        model  = SportsDailyActivityImages
        fields = ['id', 'image_url']


class SportsDailyActivitySerializer(serializers.ModelSerializer):
    images = SportsDailyActivityImagesSerializer(many=True, read_only=True)

    class Meta:
        model  = SportsDailyActivity
        fields = [
            'id', 'pt_name', 'activity_type', 'game_name',
            'date', 'time', 'school', 'participants_count',
            'created_at', 'images',
        ]


class SportsNotificationTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model  = SportsNotificationToken
        fields = ['id', 'username', 'device_token', 'created_at']
