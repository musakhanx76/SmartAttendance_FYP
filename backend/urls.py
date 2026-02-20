from django.contrib import admin
from django.urls import path
from api.views import StudentRegisterView, CreateClassView
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    # The endpoints the mobile app will call:
    path('register/', StudentRegisterView.as_view()), 
    path('create-class/', CreateClassView.as_view()),
]

# This allows us to see uploaded images (development mode only)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)