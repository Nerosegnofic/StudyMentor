import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import 'package:study_mentor_prototype/screens/auth/login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  // Add this: a final variable to hold the service instance
  final DataService dataService;

  // Update the constructor to require the service
  const ParentDashboardScreen({super.key, required this.dataService});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              widget.dataService.logout();

              // This removes all screens behind it and pushes a new LoginScreen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false, // This predicate always returns false
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Parent!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We will implement "Add Child" later
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Child',
      ),
    );
  }
}