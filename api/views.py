from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.views import APIView
from .serializers import StudentSerializer
from .models import Student
from .ai_utils import extract_face_blueprint # Import our new AI Brain

@api_view(['POST'])
def register_student(request):
    """
    Receives the Flutter form data, saves the video, 
    and triggers the AI to extract the face blueprint.
    """
    serializer = StudentSerializer(data=request.data)
    
    if serializer.is_valid():
        # 1. Save the student and the video to the server
        student = serializer.save()
        
        # 2. Get the exact folder path where Django saved the .mp4 file
        video_path = student.face_video.path
        
        print(f"AI INITIALIZED: Processing video for {student.name}...")
        
        # 3. Wake up the AI Brain! Pass the video path to dlib
        face_encoding = extract_face_blueprint(video_path)
        
        if face_encoding:
            # 4. SUCCESS! The AI found a face. Save the 128 numbers.
            student.face_encoding = face_encoding
            student.save()
            print("AI SUCCESS: Blueprint saved to PostgreSQL!")
            return Response(
                {"message": "Student registered and face scanned successfully!"}, 
                status=status.HTTP_201_CREATED
            )
        else:
            # 5. FAILURE! The AI couldn't find a face (too dark, covered camera, etc.)
            # We delete the broken record so the database stays perfectly clean.
            student.delete()
            print("AI ERROR: Registration rejected. No face found.")
            return Response(
                {"error": "AI could not detect a clear face. Please try again."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
"""from rest_framework.views import APIView
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
            }, status=status.HTTP_400_BAD_REQUEST)"""

# 2. CREATE CLASS VIEW (Added this back to stop the error!)
class CreateClassView(APIView):
    def post(self, request):
        return Response({"message": "Class creation logic goes here"})