import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';


class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _courseController = TextEditingController();
  final _studentController = TextEditingController();
  final _teacherController = TextEditingController();
  List<Map<dynamic, dynamic>> attendanceList = [];

  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _loadAttendance() {
    _database.child('attendance').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          attendanceList = [];
          final values = event.snapshot.value as Map<dynamic, dynamic>;
          values.forEach((key, value) {
            if (value is Map) {
              attendanceList.add(Map<dynamic, dynamic>.from(value));
            }
          });
          attendanceList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        });
      }
    });
  }

  Future<void> _markAttendance() async {
    if (_courseController.text.isEmpty ||
        _studentController.text.isEmpty ||
        _teacherController.text.isEmpty) {
      _showDialog('Error', 'Please fill all fields');
      return;
    }

    DateTime combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final attendanceKey = _database.child('attendance').push().key!;
      await _database.child('attendance').child(attendanceKey).set({
        'courseId': _courseController.text,
        'studentId': _studentController.text,
        'teacherId': _teacherController.text,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'timestamp': combinedDateTime.millisecondsSinceEpoch,
        'status': 'present'
      });
      _clearFields();
      _showDialog('Success', 'Attendance marked successfully!');
    } catch (e) {
      _showDialog('Error', 'Failed to mark attendance');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _courseController.clear();
    _studentController.clear();
    _teacherController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _studentController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _teacherController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _selectedTime.format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _markAttendance,
                  child: const Text('Mark Attendance'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Attendance Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final record = attendanceList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Course: ${record['courseId']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student ID: ${record['studentId']}'),
                        Text('Teacher ID: ${record['teacherId']}'),
                        Text('Date: ${record['date']}'),
                        Text('Time: ${record['time']}'),
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

  @override
  void dispose() {
    _courseController.dispose();
    _studentController.dispose();
    _teacherController.dispose();
    super.dispose();
  }
}
