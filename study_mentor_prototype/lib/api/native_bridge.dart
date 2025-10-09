import 'package:flutter/services.dart';
import 'package:study_mentor_prototype/data/data_models.dart';

/// A bridge to communicate with native Android platform code.
///
/// This class handles starting and stopping the background usage tracking service.
class NativeBridge {
  static const _channel =
  MethodChannel('com.example.study_mentor_prototype/usage_tracking');

  /// Starts the native foreground service to track app usage for a specific child.
  ///
  /// This method sends the child's ID and their configured session time
  /// to the native Android service.
  static Future<void> startTracking(Child child) async {
    try {
      final String result = await _channel.invokeMethod('startTracking', {
        'childId': child.userInfo.id,
        'sessionTimeMinutes': child.config.sessionTimeMinutes,
      });
      print('NativeBridge: $result'); // Log the success message from native
    } on PlatformException catch (e) {
      print("NativeBridge: Failed to start tracking: '${e.message}'.");
    }
  }

  /// Stops the native foreground service.
  static Future<void> stopTracking() async {
    try {
      final String result = await _channel.invokeMethod('stopTracking');
      print('NativeBridge: $result'); // Log the success message from native
    } on PlatformException catch (e) {
      print("NativeBridge: Failed to stop tracking: '${e.message}'.");
    }
  }

// TODO: Add a method handler here to listen for the "lockScreen" event from the native service.
}
