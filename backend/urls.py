from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('assignmentslogin/',           views.sfc_login,                                    name='sfc_login'),
    path('assignmentssignup/',          views.sfc_signup,                                   name='sfc_signup'),
    path('uploadfiletos3/',             views.upload_file_to_s3,                            name='sfc_upload_s3'),

    # Activities
    path('postsportsdailyactivity',     views.PostSportsDailyActivityView.as_view(),        name='sfc_post_activity'),
    path('getsportsdailyactivity',      views.GetSportsDailyActivityView.as_view(),         name='sfc_get_activities'),
    path('api/sfc/stats/',              views.sports_stats,                                 name='sfc_stats'),

    # Push notifications
    path('sportsnotificationtoken/',    views.PostSportsNotificationTokenView.as_view(),    name='sfc_post_token'),
    path('getsportsnotificationtokens/', views.GetSportsNotificationTokensView.as_view(),   name='sfc_get_tokens'),
    path('sendnotificationtoall/',      views.SendSportsActivityNotificationToAll.as_view(), name='sfc_notify_all'),
]
