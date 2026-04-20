import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/overlay/mascot_overlay_service.dart';

class StudentScreen extends StatefulWidget {
  final String fullName;
  final String uid;
  const StudentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String? _parentFullName;

  @override
  void initState() {
    super.initState();
    

    // Load parent name (existing behaviour — unchanged)
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );

    // ── Start overlay service ────────────────────────────────────────────────
    // init() requests permissions and configures monitored apps.
    // start() begins the polling loop.
    // Both calls are fire-and-forget; errors are logged inside the service.
    MascotOverlayService.instance
        .init(
          monitoredApps: MascotOverlayService.dummyMonitoredApps,
          usageThresholdMinutes: 1, // lower value makes testing easier
        )
        .then((_) => MascotOverlayService.instance.start());
  }

  @override
  void dispose() {
    // Stop monitoring when the student screen is disposed (e.g. on logout).
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ParentNameLoaded) {
          setState(() => _parentFullName = state.parentFullName);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Welcome, ${widget.fullName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        ),
        body: Center(
          child: _parentFullName == null
              ? const CircularProgressIndicator()
              : Text('Your parent is $_parentFullName'),
        ),
      ),
    );
  }
}
