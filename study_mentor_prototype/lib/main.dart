import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'screens/auth/login_screen.dart';
import 'screens/locking_screen.dart'; // Import the new locking screen
import 'services/data_service.dart';

// This top-level function is unchanged and correct.
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    home: LockingScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// Your main function is unchanged and correct.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DataService _dataService = DataService();
  _dataService.clearDatabaseForTesting();
  runApp(const MyApp());
}

// MyApp is now a StatefulWidget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ADDED: Define the MethodChannel
  static const _channel = MethodChannel('com.example.study_mentor_prototype/usage_tracking');

  // ADDED: initState to set up the listener
  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleMethod);
  }

  // ADDED: The handler function to react to native calls
  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onTimeUp":
        print("Flutter received onTimeUp callback. Showing overlay.");
        final bool isPermissionGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (isPermissionGranted) {
          await FlutterOverlayWindow.showOverlay(
            height: 1920,
            width: 1080,
            alignment: OverlayAlignment.center,
            flag: OverlayFlag.focusPointer,
          );
        } else {
          print("Overlay permission not granted. Cannot show lock screen.");
        }
        break;
      default:
        print("main.dart: Received unknown method call: ${call.method}");
    }
  }

  // Your original build method is here, completely UNCHANGED.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Mentor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
