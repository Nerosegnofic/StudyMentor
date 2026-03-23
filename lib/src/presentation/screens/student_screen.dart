import 'package:flutter/material.dart';

class StudentScreen extends StatelessWidget {
  final String fullName;
  const StudentScreen({super.key, required this.fullName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $fullName')),
      body: Center(child: Text('Student dashboard - implement features here')),
    );
  }
}
