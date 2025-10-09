import 'package:flutter/material.dart';
import '../../data/data_models.dart';
import '../../services/data_service.dart';
import '../parent/parent_dashboard_screen.dart';
import '../child/child_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Create an instance of our service
  final DataService _dataService = DataService();

  // This list will hold all users (parents and children) for display
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // A method to load data from the DataService
  Future<void> _loadUsers() async {
    await _dataService.loadDatabase();
    // Combine parents and children into a single list for the UI
    final parents = _dataService.getParents();
    final children = _dataService.getChildren();
    setState(() {
      _users = [...parents, ...children];
      _isLoading = false;
    });
  }

  // This function shows the password entry dialog
  void _showPasswordDialog(dynamic user) {
    final passwordController = TextEditingController();
    final isParent = user is Parent;
    final username = user.userInfo.username;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Password for $username'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredPassword = passwordController.text;
                final actualPassword = user.userInfo.password;

                if (enteredPassword == actualPassword) {
                  // If password is correct, log the user in
                  final loggedInUser = _dataService.login(username, enteredPassword);

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Navigate to the correct screen
                  if (loggedInUser is Parent) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => ParentDashboardScreen(dataService: _dataService)),
                    );
                  } else if (loggedInUser is Child) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => ChildDashboardScreen(dataService: _dataService)),
                    );
                  }
                } else {
                  // Show an error for wrong password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wrong password. Please try again.')),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isParent = user is Parent;
          final username = user.userInfo.username;
          final icon = isParent ? Icons.person : Icons.child_care;

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Icon(icon),
              title: Text(username),
              subtitle: Text(isParent ? 'Parent Account' : 'Child Account'),
              onTap: () => _showPasswordDialog(user),
            ),
          );
        },
      ),
    );
  }
}