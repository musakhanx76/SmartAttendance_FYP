from django.db import models

class Student(models.Model):
    name = models.CharField(max_length=100)
    rollNo = models.CharField(max_length=50, unique=True)
    
    # CHANGED: ImageField is now FileField to accept .mp4 videos
    face_video = models.FileField(upload_to='student_videos/') 

    def __str__(self):
        return f"{self.name} - {self.rollNo}"
"""class Student(models.Model):
    name = models.CharField(max_length=100)
    rollNo = models.CharField(max_length=50, unique=True)
    image = models.ImageField(upload_to='post_images/')

    # This is the "return function" (Dunder Str)
    def __str__(self):
        return f"{self.name} - {self.rollNo}"""
class ClassSession(models.Model):
    subject_name = models.CharField(max_length=100)
    class_code = models.CharField(max_length=6, unique=True) # e.g. "X9D2A1"
    teacher_name = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.subject_name} ({self.class_code})"

class Attendance(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    session = models.ForeignKey(ClassSession, on_delete=models.CASCADE)
    date = models.DateField(auto_now_add=True)
    time = models.TimeField(auto_now_add=True)
    is_present = models.BooleanField(default=True)
