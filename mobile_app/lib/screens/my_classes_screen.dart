import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({Key? key}) : super(key: key);

  @override
  _MyClassesScreenState createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  bool _isLoading = true;
  Map<String, List<dynamic>> _groupedStudents = {};

  @override
  void initState() {
    super.initState();
    _fetchMyStudents();
  }

  Future<void> _fetchMyStudents() async {
    setState(() => _isLoading = true);
    
    // 🔥 CHANGE TO YOUR IP
    String url = 'http://192.168.100.5:8000/my_students/';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        List<dynamic> allStudents = response.data['students'] ?? [];
        
        // Group the students by their course code (e.g., "PS101")
        Map<String, List<dynamic>> grouped = {};
        for (var student in allStudents) {
          String course = "${student['course_code']} - ${student['class_name']}";
          if (!grouped.containsKey(course)) grouped[course] = [];
          grouped[course]!.add(student);
        }

        setState(() { _groupedStudents = grouped; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch classes.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeStudent(int enrollmentId, String courseKey, int index) async {
    // 🔥 CHANGE TO YOUR IP
    String url = 'http://192.168.100.5:8000/remove_student/$enrollmentId/';

    try {
      var response = await Dio().delete(url);
      if (response.statusCode == 200) {
        setState(() {
          _groupedStudents[courseKey]!.removeAt(index);
          // If the class is now empty, remove the class folder entirely
          if (_groupedStudents[courseKey]!.isEmpty) {
            _groupedStudents.remove(courseKey);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message']), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove student.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Classes & Students'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : _groupedStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_rounded, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("No classes found.", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const Text("Approve pending students to create your classes.", style: TextStyle(color: Color.fromARGB(255, 143, 143, 143))),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _groupedStudents.keys.map((courseKey) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        iconColor: Colors.deepPurpleAccent,
                        textColor: Colors.deepPurpleAccent,
                        title: Text(
                          courseKey,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('${_groupedStudents[courseKey]!.length} Student(s) Enrolled'),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple[50],
                          child: const Icon(Icons.class_rounded, color: Colors.deepPurpleAccent),
                        ),
                        children: _groupedStudents[courseKey]!.asMap().entries.map((entry) {
                          int index = entry.key;
                          var student = entry.value;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                            leading: const Icon(Icons.person, color: Colors.grey),
                            title: Text(student['student_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Roll No: ${student['rollNo']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                              tooltip: 'Remove from Class',
                              onPressed: () {
                                _removeStudent(student['enrollment_id'], courseKey, index);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}