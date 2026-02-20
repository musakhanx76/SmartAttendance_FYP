from rest_framework import serializers
from .models import Student , ClassSession

class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = ['name', 'rollNo', 'image'] # Ensure these match the model above

class ClassSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassSession
        fields = '__all__'