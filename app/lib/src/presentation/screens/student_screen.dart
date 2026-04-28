import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../widgets/parent_verification_dialog.dart';
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
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );
    MascotOverlayService.instance
        .init(
          monitoredApps: MascotOverlayService.dummyMonitoredApps,
          usageThresholdMinutes: 1,
        )
        .then((_) => MascotOverlayService.instance.start());
  }

  @override
  void dispose() {
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _parentFullName = null);
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );
  }

  void _showVerificationDialog({String? errorMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ParentVerificationDialog(
        errorMessage: errorMessage,
        onSubmit: (email, password) {
          Navigator.of(dialogContext).pop();
          context.read<AuthBloc>().add(
            VerifyParentAndLogoutRequested(
              studentUid: widget.uid,
              parentEmail: email,
              parentPassword: password,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Back button triggers the parent verification flow instead of
        // navigating away — same as tapping the logout button.
        if (!didPop) {
          context.read<AuthBloc>().add(
            StudentLogoutVerificationRequested(studentUid: widget.uid),
          );
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ParentNameLoaded) {
            setState(() => _parentFullName = state.parentFullName);
          }
          if (state is StudentLogoutVerificationRequired) {
            _showVerificationDialog();
          }
          if (state is ParentVerificationFailed) {
            _showVerificationDialog(errorMessage: state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Welcome, ${widget.fullName}'),
            automaticallyImplyLeading: false, // hide back arrow on home screen
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(
                    StudentLogoutVerificationRequested(studentUid: widget.uid),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: _parentFullName == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your parent is $_parentFullName',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
