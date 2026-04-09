from django.contrib import admin
from .models import Student, Attendance, ClassRoom, Enrollment

admin.site.register(Student)
admin.site.register(Attendance)
admin.site.register(ClassRoom)
admin.site.register(Enrollment)