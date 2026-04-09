import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _attendanceRecords = [];
  String _message = "Select a date to view attendance.";

  @override
  void initState() {
    super.initState();
    _fetchReports(); // Fetch today's records automatically when screen opens
  }

  // Helper function to format the date exactly how Django expects it (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchReports() async {
    setState(() { _isLoading = true; _attendanceRecords = []; });

    String dateStr = _formatDateForApi(_selectedDate);
    // 🔥 IMPORTANT: Change this to your computer's actual IP address!
    String url = 'http://192.168.100.5:8000/get_report/$dateStr/';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200) {
        setState(() {
          _attendanceRecords = response.data['records'] ?? [];
          _message = response.data['message'] ?? "No records found.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error fetching data. Ensure the server is running.";
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Opens the native Android/iOS Calendar pop-up
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023), // How far back they can search
      lastDate: DateTime.now(),  // They can't search in the future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orangeAccent, // Highlights the calendar in your app colors
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
      _fetchReports(); // Fetch new data as soon as they pick a new date!
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // The Top Calendar Control Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      displayDate,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[50],
                    foregroundColor: Colors.orange[900],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _selectDate(context),
                  child: const Text('Change Date'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // The Data List Area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
              : _attendanceRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(_message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _attendanceRecords.length,
                    itemBuilder: (context, index) {
                      var record = _attendanceRecords[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[50],
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green),
                          ),
                          title: Text(
                            record['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text('Roll No: ${record['rollNo']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                record['status'],
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record['time'],
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}