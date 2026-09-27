from django.db import models


class SFCUser(models.Model):
    username   = models.CharField(max_length=100, unique=True)
    password   = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'firstdemoapp2_assignmentsuserdata'
        managed  = False

    def __str__(self):
        return self.username


class SportsDailyActivity(models.Model):
    pt_name            = models.CharField(max_length=100)
    activity_type      = models.CharField(max_length=10000)
    game_name          = models.CharField(max_length=100)
    date               = models.CharField(max_length=20)
    time               = models.CharField(max_length=50)
    school             = models.CharField(max_length=100)
    participants_count = models.IntegerField(default=0)
    created_at         = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'firstdemoapp2_sportsdailyactivity'
        managed  = False
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.pt_name} | {self.school} | {self.date}"


class SportsDailyActivityImages(models.Model):
    activity  = models.ForeignKey(
        SportsDailyActivity,
        related_name='images',
        on_delete=models.CASCADE,
    )
    image_url = models.URLField()

    class Meta:
        db_table = 'firstdemoapp2_sportsdailyactivityimages'
        managed  = False

    def __str__(self):
        return f"Image → activity {self.activity_id}"


class SportsNotificationToken(models.Model):
    username     = models.CharField(max_length=100)
    device_token = models.CharField(max_length=512, unique=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'firstdemoapp2_sportsnotificationtoken'
        managed  = False

    def __str__(self):
        return f"{self.username} — {self.device_token[:30]}…"
