import cv2
import face_recognition

def extract_face_blueprint(video_path):
    """
    Opens the video, extracts a clean frame, and uses a CNN 
    to generate a 128-dimensional face encoding.
    """
    try:
        # 1. Open the video file using OpenCV
        cap = cv2.VideoCapture(video_path)
        
        # 2. Fast forward to 2.5 seconds (2500 milliseconds)
        # This guarantees we grab the frame where they are looking straight!
        cap.set(cv2.CAP_PROP_POS_MSEC, 2500) 
        
        success, frame = cap.read()
        cap.release()

        if not success:
            print("AI ERROR: Could not extract frame from video.")
            return None

        # 3. OpenCV reads colors in BGR, but the AI needs RGB. Let's convert it.
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # 4. Use dlib's CNN (Convolutional Neural Network) to find the face
        boxes = face_recognition.face_locations(rgb_frame, model="cnn")
        
        if not boxes:
            print("AI ERROR: No face detected in the frame.")
            return None

        # 5. Extract the 128-dimensional mathematical blueprint
        encodings = face_recognition.face_encodings(rgb_frame, boxes)
        
        if encodings:
            # Convert the numpy array to a standard Python list so PostgreSQL can save it
            return encodings[0].tolist() 
            
        return None

    except Exception as e:
        print(f"AI SYSTEM FAILURE: {e}")
        return None