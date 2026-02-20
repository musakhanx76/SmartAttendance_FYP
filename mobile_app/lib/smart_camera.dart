import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SmartFaceCamera extends StatefulWidget {
  final Function(File) onImageCaptured;

  const SmartFaceCamera({super.key, required this.onImageCaptured});

  @override
  State<SmartFaceCamera> createState() => _SmartFaceCameraState();
}

class _SmartFaceCameraState extends State<SmartFaceCamera> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 1. Find available cameras
    final cameras = await availableCameras();
    // 2. Select the Front Camera (Selfie)
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // 3. Setup the controller with "Max" resolution for best details
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.max, // <--- THIS ENSURES "PIXELS AT ITS BEST"
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isTakingPicture) return;
    setState(() => _isTakingPicture = true);

    try {
      await _initializeControllerFuture;
      
      // Capture the high-res image
      final image = await _controller!.takePicture();
      
      // Send it back to the registration screen
      widget.onImageCaptured(File(image.path));
      
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. The Camera Feed
                CameraPreview(_controller!),
                
                // 2. The "Face Lock" Overlay (Dark background with clear oval)
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black54, 
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.clear,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 350,
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(150) // Makes it an oval
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Instructions
                const Positioned(
                  top: 100,
                  child: Text(
                    "Align Face in Oval",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

                // 4. Capture Button
                Positioned(
                  bottom: 50,
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.blueAccent, width: 4),
                      ),
                      child: _isTakingPicture 
                        ? const CircularProgressIndicator() 
                        : const Icon(Icons.face, size: 40, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}