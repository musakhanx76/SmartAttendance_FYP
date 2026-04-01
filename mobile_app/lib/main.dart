import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'smart_camera.dart'; // Import our new camera file
import 'screens/teacher_dashboard.dart';
import 'screens/welcome_screen.dart';

void main() {
  // Ensures plugins are loaded before app starts
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const WelcomeScreen(),
  ));
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  File? _videoFile;
  
  // Base URL pointing to your laptop's IP address
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.22.121.6:8000'));
  bool _isUploading = false;


  void _openSmartCamera() async {
    // 1. Get the available cameras on the phone
    final cameras = await availableCameras();

    // 2. Open the camera screen and wait for it to return a file path
    final String? videoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartFaceCamera(cameras: cameras),
      ),
    );

    // 3. If a video was recorded successfully, save it to our state
    if (videoPath != null) {
      setState(() {
        _videoFile = File(videoPath); 
      });
    }
  }

  Future<void> _register() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face scan required!"))
      );
      return;
    }

    setState(() => _isUploading = true);

   try {
      FormData formData = FormData.fromMap({
        "name": nameController.text,
        "rollNo": rollNoController.text,
        "face_video": await MultipartFile.fromFile(_videoFile!.path, filename: "student.mp4"),
      });

      // Sending data to the Django /register/ endpoint
      Response response = await _dio.post('/register/', data: formData);

      // THE FIX: Check for success, stop the spinner, and reset the form!
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _isUploading = false;      // 1. Stop the loading circle
          _videoFile = null;         // 2. Reset the Face Scan circle back to grey
          nameController.clear();    // 3. Empty the Name text box
          rollNoController.clear();  // 4. Empty the Roll No text box
        });

        // Show a nice green success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student Enrolled Successfully!"), 
              backgroundColor: Colors.green
            ),
          );
        }
      }

    } catch (e) {
      // If something goes wrong, stop the spinner so the user can try again
      setState(() => _isUploading = false);
      
      if (e is DioException) {
        print("DIO ERROR: ${e.response?.statusCode} - ${e.response?.data}");
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Face Enrollment", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            const Text(
              "We need a high-detail scan for the database.", 
              style: TextStyle(color: Colors.grey)
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController, 
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
              controller: rollNoController, 
              decoration: const InputDecoration(labelText: "Roll Number", border: OutlineInputBorder())
            ),
            const SizedBox(height: 30),

           // THE FACE SCAN AREA
            GestureDetector(
              onTap: _openSmartCamera,
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _videoFile == null ? Colors.grey : Colors.green,
                    width: 4
                  ),
                ),
                child: _videoFile == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face_retouching_natural, size: 50, color: Colors.blue),
                        Text("Tap to Scan Face", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 50, color: Colors.green),
                        Text("Scan Complete!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
              ), // Container ends cleanly here!
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("COMPLETE ENROLLMENT", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}