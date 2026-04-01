from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static

# 1. Temporarily removed CreateClassView from this import
from api.views import register_student, mark_attendance, delete_student

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # 2. Temporarily comment out this path so Django ignores it
    # path('api/create_class/', CreateClassView.as_view(), name='create_class'),
    
    path('register/', register_student, name='register_student'),
    path('mark_attendance/', mark_attendance, name='mark_attendance'),
    path('delete_student/<path:roll_number>/', delete_student, name='delete_student'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)