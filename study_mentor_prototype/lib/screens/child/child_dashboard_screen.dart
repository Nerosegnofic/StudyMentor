import 'package:flutter/material.dart';
import 'package:study_mentor_prototype/screens/auth/login_screen.dart';
import '../../services/data_service.dart';

class ChildDashboardScreen extends StatefulWidget {
  // Add this: a final variable to hold the service instance
  final DataService dataService;

  // Update the constructor to require the service
  const ChildDashboardScreen({super.key, required this.dataService});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              widget.dataService.logout();
              // This should be replaced by switch useres only
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
          'Welcome, Child!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}