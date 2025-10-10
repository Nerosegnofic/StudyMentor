import 'package:flutter/material.dart';
import 'package:study_mentor_prototype/api/permission_bridge.dart';
import 'package:study_mentor_prototype/services/permission_service.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen>
    with WidgetsBindingObserver {
  bool _hasUsageStats = false;
  bool _hasSystemAlertWindow = false;

  @override
  void initState() {
    super.initState();
    // Observe app lifecycle changes to re-check permissions when the user
    // returns from the settings screen.
    WidgetsBinding.instance.addObserver(this);
    // Initial check when the screen loads.
    _checkPermissions();
  }

  @override
  void dispose() {
    // Clean up the observer.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns to the app, re-check the permissions.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final hasUsage = await PermissionBridge.hasUsageStatsPermission();
    final hasAlert = await PermissionBridge.hasSystemAlertWindowPermission();

    setState(() {
      _hasUsageStats = hasUsage;
      _hasSystemAlertWindow = hasAlert;
    });

    // If all permissions are granted, you might want to automatically navigate away.
    // For example:
    // if (hasUsage && hasAlert) {
    //   Navigator.of(context).pop(); // Go back to the previous screen
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Permissions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For the study mentor feature to work, we need two special permissions. Please grant them in the system settings.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _PermissionTile(
              title: 'Usage Stats Access',
              subtitle: 'Allows the app to see which app is currently being used.',
              isGranted: _hasUsageStats,
              onRequest: () => PermissionService.requestUsageStatsPermission(),
            ),
            const SizedBox(height: 16),
            _PermissionTile(
              title: 'Display Over Other Apps',
              subtitle: 'Allows the app to show the quiz screen when study time is over.',
              isGranted: _hasSystemAlertWindow,
              onRequest: () => PermissionService.requestSystemAlertWindowPermission(),
            ),
            const Spacer(),
            if (_hasUsageStats && _hasSystemAlertWindow)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text('All permissions granted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// A reusable widget for displaying the state of a single permission.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.onRequest,
  });

  final String title;
  final String subtitle;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle : Icons.error,
          color: isGranted ? Colors.green : Colors.orange,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isGranted
            ? const Text('Granted', style: TextStyle(color: Colors.green))
            : ElevatedButton(
          onPressed: onRequest,
          child: const Text('Grant'),
        ),
      ),
    );
  }
}
