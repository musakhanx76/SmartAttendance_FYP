import cv2
import face_recognition
import numpy as np
import os

def extract_face_blueprint(video_path):
    """
    Opens the video, extracts a clean frame, and uses a CNN
    to generate a 128-dimensional face encoding.
    """
    try:
        # 1. Open the video file using OpenCV
        cap = cv2.VideoCapture(video_path)

        # 2. Fast forward to 2.5 seconds (2500 milliseconds)
        cap.set(cv2.CAP_PROP_POS_MSEC, 2500)

        success, frame = cap.read()
        cap.release()

        if not success:
            print("AI ERROR: Could not extract frame from video.")
            return None

        # 3. OpenCV reads colors in BGR, but the AI needs RGB. Let's convert it.
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # 4. Use dlib's CNN (Convolutional Neural Network) to find the face
        boxes = face_recognition.face_locations(rgb_frame, model="hog")

        if not boxes:
            print("AI ERROR: No face detected in the frame.")
            return None
            
        # Extract the blueprint
        encodings = face_recognition.face_encodings(rgb_frame, boxes)
        
        if not encodings:
            return None
            
        return encodings[0].tolist()

    except Exception as e:
        print(f"AI SYSTEM FAILURE: {e}")
        return None

def scan_classroom_faces(file_path, known_students_dict):
    """
    Accepts EITHER an image or a short video.
    Returns a list of Roll Numbers that were successfully recognized.
    """
    present_students = []
    
    # --- HELPER FUNCTION: Scans a single frame ---
    def process_single_image(image_to_scan):
        found_rolls = []
        face_locations = face_recognition.face_locations(image_to_scan)
        live_encodings = face_recognition.face_encodings(image_to_scan, face_locations)
        
        for live_encoding in live_encodings:
            best_match_roll_no = None
            lowest_distance = 1.0 
            
            for roll_no, saved_encoding in known_students_dict.items():
                if not saved_encoding:
                    continue
                saved_encoding_np = np.array(saved_encoding)
                distance = face_recognition.face_distance([saved_encoding_np], live_encoding)[0]
                
                if distance < lowest_distance:
                    lowest_distance = distance
                    best_match_roll_no = roll_no
                    
            if lowest_distance <= 0.38 and best_match_roll_no:
                found_rolls.append(best_match_roll_no)
                
        return found_rolls

    try:
        # Check if the file is a video or an image
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext in ['.mp4', '.avi', '.mov', '.mkv']:
            print("AI INITIALIZED: Processing Classroom VIDEO...")
            video_capture = cv2.VideoCapture(file_path)
            
            # Get the Frames Per Second (FPS) of the video
            fps = int(video_capture.get(cv2.CAP_PROP_FPS))
            total_frames = int(video_capture.get(cv2.CAP_PROP_FRAME_COUNT))
            
            if fps == 0:
                fps = 30 
                
            print(f"AI STATUS: Video is ~{total_frames // fps} seconds long. Scanning 1 frame per second...")

            # Loop through the video, jumping forward 1 second at a time
            for frame_num in range(0, total_frames, fps):
                video_capture.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
                ret, frame = video_capture.read()
                
                if ret:
                    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    found_in_frame = process_single_image(rgb_frame)
                    present_students.extend(found_in_frame)
                    
            video_capture.release()
            
        else:
            print("AI INITIALIZED: Processing Classroom IMAGE...")
            classroom_image = face_recognition.load_image_file(file_path)
            found_in_image = process_single_image(classroom_image)
            present_students.extend(found_in_image)

        # Remove duplicates
        final_present_list = list(set(present_students))
        print(f"AI SUCCESS: Verified {len(final_present_list)} students!")
        
        return final_present_list, "Success"
        
    except Exception as e:
        print(f"AI MATCHING FAILURE: {e}")
        return [], str(e)