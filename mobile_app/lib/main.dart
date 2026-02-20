import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'smart_camera.dart'; // Import our new camera file

void main() {
  // Ensures plugins are loaded before app starts
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RegisterScreen(),
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
  File? _image;
  
  // Base URL pointing to your laptop's IP address
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.100.5:8000'));
  bool _isUploading = false;

  // This function opens our Custom Smart Camera
  void _openSmartCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartFaceCamera(
          onImageCaptured: (File capturedImage) {
            setState(() {
              _image = capturedImage;
            });
            Navigator.pop(context); // Close camera after taking photo
          },
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face scan required!"))
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = _image!.path.split('/').last;
      
      // FIXED: Labels match your Django Serializer fields exactly
      FormData formData = FormData.fromMap({
        "name": nameController.text,
        "rollNo": rollNoController.text, 
        "image": await MultipartFile.fromFile(_image!.path, filename: fileName),
      });

      // Sending data to the Django /register/ endpoint
      Response response = await _dio.post('/register/', data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server: ${response.data['message']}"),
            backgroundColor: Colors.green,
          )
        );
      }
      
    } catch (e) {
      String errorMsg = "Registration Failed";
      
      // Extracts specific error messages from Django if validation fails (400 error)
      if (e is DioException && e.response != null) {
        errorMsg = e.response?.data['message'] ?? e.response?.data.toString() ?? "Server Error";
      } else {
        errorMsg = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
                    color: _image == null ? Colors.grey : Colors.green, 
                    width: 4
                  ),
                  image: _image != null 
                    ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                    : null
                ),
                child: _image == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face_retouching_natural, size: 50, color: Colors.blue),
                        Text("Tap to Scan Face", style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                  : null,
              ),
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