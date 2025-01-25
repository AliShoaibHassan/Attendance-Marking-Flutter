import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();

  void _submitFeedback() {
    final feedback = _feedbackController.text.trim();
    if (feedback.isNotEmpty) {
      FirebaseDatabase.instance.ref('feedback').push().set({'message': feedback});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback Submitted')));
      _feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(labelText: 'Your Feedback'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
