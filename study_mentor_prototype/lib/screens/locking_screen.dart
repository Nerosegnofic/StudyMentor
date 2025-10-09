import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class LockingScreen extends StatefulWidget {
  const LockingScreen({super.key});

  @override
  State<LockingScreen> createState() => _LockingScreenState();
}

class _LockingScreenState extends State<LockingScreen> {
  @override
  void initState() {
    super.initState();
    // Example of listening for data from the main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      print("Data from main app: $data");
    });
  }

  @override
  Widget build(BuildContext context) {
    // The UI of the screen that will cover everything else
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_off_outlined,
              color: Colors.orangeAccent,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              "Study Time Over!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Time for a quick quiz.",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),

            // This is where you would place your quiz widget.
            // For now, we will add a button to close the overlay for testing.
            // In the final version, this button should only appear after
            // the quiz is successfully completed.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                // This call closes the overlay window.
                FlutterOverlayWindow.closeOverlay();
              },
              child: const Text(
                'Start Quiz (Test Close)',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
