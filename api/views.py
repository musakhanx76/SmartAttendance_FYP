from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.views import APIView
from .serializers import StudentSerializer
"""from .models import Student
from .ai_utils import extract_face_blueprint # Import our new AI Brain"""
from django.core.files.storage import FileSystemStorage
from .models import Student, Attendance
from .ai_utils import extract_face_blueprint, scan_classroom_faces
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

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






@api_view(['POST'])
def mark_attendance(request):
    """
    Receives a classroom photo/video from the teacher, scans it using AI,
    and marks recognized students as Present in the database.
    """
    # 1. Grab the uploaded file from the request
    uploaded_file = request.FILES.get('classroom_media')
    
    if not uploaded_file:
        return Response({"error": "No image or video file provided."}, status=status.HTTP_400_BAD_REQUEST)

    # 2. Temporarily save the file so OpenCV can read it
    fs = FileSystemStorage()
    filename = fs.save(uploaded_file.name, uploaded_file)
    file_path = fs.path(filename)

    try:
        # 3. Pull ALL known blueprints from the PostgreSQL vault
        all_students = Student.objects.exclude(face_encoding__isnull=True)
        
        # Format them into the dictionary our AI expects: {"roll_no": [128_numbers]}
        known_students_dict = {student.rollNo: student.face_encoding for student in all_students}
        
        if not known_students_dict:
            return Response({"error": "No students registered in the database yet!"}, status=status.HTTP_400_BAD_REQUEST)

        # 4. Wake up the Hybrid AI!
        present_roll_nos, message = scan_classroom_faces(file_path, known_students_dict)
        
        # 5. Save the results to the Attendance table
        marked_names = []
        for roll_no in present_roll_nos:
            student = Student.objects.get(rollNo=roll_no)
            
            # get_or_create prevents errors if the teacher scans the same class twice in one day
            attendance_record, created = Attendance.objects.get_or_create(
                student=student,
                status="Present"
                # date and time are added automatically by the model
            )
            marked_names.append(student.name)

        # 6. Clean up: Delete the teacher's heavy video/photo to save server space
        fs.delete(filename)

        # 7. Send the success list back to the Flutter app!
        return Response({
            "message": "AI Scanning Complete!",
            "recognized_count": len(marked_names),
            "present_students": marked_names
        }, status=status.HTTP_200_OK)

    except Exception as e:
        fs.delete(filename) # Ensure we still clean up if it crashes
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    
@csrf_exempt
def delete_student(request, roll_number):
    if request.method == 'DELETE':
        # 1. Clean the incoming text (remove hidden spaces)
        clean_roll = roll_number.strip()
        
        # 2. Print it to your terminal so you can see exactly what arrived!
        print(f"--- ATTEMPTING TO DELETE ROLL NUMBER: '{clean_roll}' ---")
        
        try:
            # 3. Use __iexact for Case-Insensitive matching
            student = Student.objects.get(rollNo__iexact=clean_roll)
            student.delete()
            
            print(f"--- SUCCESS: {clean_roll} deleted! ---")
            return JsonResponse({'status': 'success', 'message': f'Student {clean_roll} deleted successfully.'}, status=200)
        
        except Student.DoesNotExist:
            print(f"--- FAILED: {clean_roll} is not in the database! ---")
            return JsonResponse({'status': 'error', 'message': 'Student not found.'}, status=404)
            
    return JsonResponse({'status': 'error', 'message': 'Invalid request method.'}, status=400)
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