from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
# Check these imports! They must match your actual filenames
from .models import Student 
from .serializers import StudentSerializer

# 1. REGISTER STUDENT API
class StudentRegisterView(APIView):
    parser_classes = (MultiPartParser, FormParser) 

    def post(self, request, *args, **kwargs):
        serializer = StudentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({
                "status": "success", 
                "message": "Student Registered successfully!"
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                "status": "error", 
                "message": f"Registration failed: {serializer.errors}",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

# 2. CREATE CLASS VIEW (Added this back to stop the error!)
class CreateClassView(APIView):
    def post(self, request):
        return Response({"message": "Class creation logic goes here"})