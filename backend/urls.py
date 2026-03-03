from django.contrib import admin
from django.urls import path
from api.views import register_student, CreateClassView
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    # The endpoints the mobile app will call: 
    path('api/create_class/', CreateClassView.as_view(), name='create_class'),
    path('register/', register_student, name='register_student'),
]

# This allows us to see uploaded images (development mode only)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)