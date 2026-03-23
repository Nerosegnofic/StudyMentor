import 'package:flutter/material.dart';

class ParentScreen extends StatelessWidget {
  final String fullName;
  const ParentScreen({super.key, required this.fullName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $fullName')),
      body: Center(child: Text('Parent dashboard - implement features here')),
    );
  }
}
