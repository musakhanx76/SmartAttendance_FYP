import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DeleteStudentScreen extends StatefulWidget {
  const DeleteStudentScreen({Key? key}) : super(key: key);

  @override
  _DeleteStudentScreenState createState() => _DeleteStudentScreenState();
}

class _DeleteStudentScreenState extends State<DeleteStudentScreen> {
  final TextEditingController _rollNumberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _deleteStudent(String rollNumber) async {
    setState(() { _isLoading = true; });

    try {
      var dio = Dio();
      
      // 🔥 IMPORTANT: Change this to your computer's actual IP address!
      String url = 'http://10.22.121.6:8000/delete_student/$rollNumber/';
      
      var response = await dio.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green),
        );
        _rollNumberController.clear();
      }
    } on DioException catch (e) {
      String errorMsg = 'Failed to delete student.';
      if (e.response?.statusCode == 404) {
        errorMsg = 'Student not found in database.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // A safety popup so the teacher doesn't delete by mistake
  void _showConfirmationDialog() {
    String rollNumber = _rollNumberController.text.trim();
    if (rollNumber.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to completely remove student $rollNumber from the system? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteStudent(rollNumber);
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'Remove Student Record',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the Roll Number of the student you wish to remove from the facial recognition database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _rollNumberController,
              decoration: InputDecoration(
                labelText: 'Student Roll Number',
                prefixIcon: const Icon(Icons.badge_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _showConfirmationDialog,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.delete_forever),
                label: Text(
                  _isLoading ? 'Processing...' : 'Delete Student',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}