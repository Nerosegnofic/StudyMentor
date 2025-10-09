import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'screens/auth/login_screen.dart';
import 'screens/locking_screen.dart'; // Import the new locking screen
import 'services/data_service.dart';

// STEP 1: DEFINE THE OVERLAY ENTRY POINT
// This must be a top-level or static function. The @pragma annotation is required.
@pragma("vm:entry-point")
void overlayMain() {
  // This is a separate Flutter app instance that runs for the overlay.
  runApp(const MaterialApp(
    home: LockingScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// The main function is the starting point for your main Flutter app.
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
