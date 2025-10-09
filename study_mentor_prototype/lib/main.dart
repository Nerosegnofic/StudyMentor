import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'services/data_service.dart';

// The main function is the starting point for all Flutter apps.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DataService _dataService = DataService();
  _dataService.clearDatabaseForTesting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Mentor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // This sets the LoginScreen as the first screen of the app.
      home: const LoginScreen(),
    );
  }
}