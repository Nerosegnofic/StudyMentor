import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../../bloc/students/students_state.dart';
import '../../../bloc/snapshot/snapshot_bloc.dart';
import '../../../bloc/reports/reports_bloc.dart';
import '../../../domain/models/student_model.dart';
import '../../widgets/parent_home/branded_header.dart';
import '../../widgets/parent_home/child_card.dart';
import '../../widgets/parent_home/ai_summary_carousel.dart';
import 'student_profile_dashboard.dart';
import '../../../../l10n/app_localizations.dart';

class ParentHomeDashboard extends StatefulWidget {
  final String parentUid;
  final String fullName;
  final VoidCallback onAddStudentPressed;

  const ParentHomeDashboard({
    super.key,
    required this.parentUid,
    required this.fullName,
    required this.onAddStudentPressed,
  });

  @override
  State<ParentHomeDashboard> createState() => _ParentHomeDashboardState();
}

class _ParentHomeDashboardState extends State<ParentHomeDashboard> {
  List<StudentModel> _realStudents = [];

  @override
  void initState() {
    super.initState();
    final currentState = context.read<StudentsBloc>().state;
    if (currentState is StudentsLoaded) {
      _realStudents = currentState.students;
    }
    context.read<StudentsBloc>().add(
          LoadStudentsRequested(parentUid: widget.parentUid),
        );
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    context.read<StudentsBloc>().add(
          LoadStudentsRequested(parentUid: widget.parentUid),
        );
  }

  // ── Delete unverified student ─────────────────────────────────────────────

  Future<void> _confirmDeleteUnverified(StudentModel student) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StudentsBloc>(),
        child: _UnverifiedStudentDeleteDialog(
          student: student,
          parentUid: widget.parentUid,
        ),
      ),
    );
  }

  // ── Navigation to student profile ─────────────────────────────────────────

  Future<void> _openConfig(StudentModel student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AuthBloc>()),
            BlocProvider.value(value: context.read<SnapshotBloc>()),
            BlocProvider.value(value: context.read<ReportsBloc>()),
          ],
          child: StudentProfileDashboard(student: student),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state is StudentsLoaded) {
          setState(() {
            _realStudents = state.students;
          });
        } else if (state is StudentDeleted) {
          context.read<StudentsBloc>().add(
            LoadStudentsRequested(parentUid: widget.parentUid),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Stack(
            children: [
              // ── Scrollable content ──────────────────────────────────────
              RefreshIndicator(
                onRefresh: _refreshAll,
                color: const Color(0xFF2196F3),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Component 1 — Branded Header (sticky / pinned)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        child: BrandedHeader(
                          parentName: widget.fullName,
                          parentUid: widget.parentUid,
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 5),
                        child: AiSummaryCarousel(parentUid: widget.parentUid),
                      ),
                    ),

                    // Component 2 — "My Children" subheader
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 0,
                          left: 20,
                          bottom: 12,
                        ),
                        child: Text(
                          AppLocalizations.of(context).myChildrenTitle,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),

                    // Component 3 — Child Cards (real)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final student = _realStudents[index];
                          return ChildCard(
                            student: student,
                            onTap: student.isEmailVerified
                                ? () => _openConfig(student)
                                : null,
                            onDelete: student.isEmailVerified
                                ? null
                                : () => _confirmDeleteUnverified(student),
                          );
                        },
                        childCount: _realStudents.length,
                      ),
                    ),

                    // Bottom spacer so FAB doesn't overlap last card
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),

              // Component 5 — FAB (fixed bottom-right)
              Positioned(
                bottom: 30,
                right: 30,
                child: _DashboardFab(onPressed: widget.onAddStudentPressed),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Unverified student delete dialog ─────────────────────────────────────────

class _UnverifiedStudentDeleteDialog extends StatefulWidget {
  final StudentModel student;
  final String parentUid;

  const _UnverifiedStudentDeleteDialog({
    required this.student,
    required this.parentUid,
  });

  @override
  State<_UnverifiedStudentDeleteDialog> createState() =>
      _UnverifiedStudentDeleteDialogState();
}

class _UnverifiedStudentDeleteDialogState
    extends State<_UnverifiedStudentDeleteDialog> {
  final _passCtl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _passCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passCtl.text.trim();
    if (password.isEmpty) {
      setState(() => _errorText =
          AppLocalizations.of(context).validatorStudentPasswordRequired);
      return;
    }
    setState(() => _errorText = null);
    context.read<StudentsBloc>().add(
      DeleteStudentRequested(
        studentUid: widget.student.uid,
        studentEmail: widget.student.email,
        studentPassword: password,
        parentUid: widget.parentUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isLoading,
      child: BlocListener<StudentsBloc, StudentsState>(
        listener: (context, state) {
          if (state is StudentDeleteLoading) {
            setState(() => _isLoading = true);
          } else if (state is StudentDeleted &&
              state.studentUid == widget.student.uid) {
            Navigator.of(context).pop();
          } else if (state is StudentDeleteError) {
            setState(() {
              _isLoading = false;
              _errorText = state.message;
            });
          }
        },
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_remove_outlined,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.removeStudentTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.removeStudentConfirmMessage(widget.student.fullName),
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtl,
                  obscureText: _obscure,
                  autofocus: true,
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: loc.fieldStudentPassword,
                    errorText: _errorText,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.red.shade600, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.red.shade600, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(loc.commonCancel,
                  style: const TextStyle(color: Color(0xFF666666))),
            ),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(loc.removeButton),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _DashboardFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _DashboardFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onPressed,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

// ── Sticky header delegate ────────────────────────────────────────────────────
// Wraps BrandedHeader so it can be used inside SliverPersistentHeader(pinned).
// The fixed height accommodates the SafeArea top inset + padding + content row.

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyHeaderDelegate({required this.child});

  // 120px covers the status bar (up to ~48px) + 20px top padding + 50px row
  // + 20px bottom padding + small buffer. Adjust if needed per device.
  static const double _height = 120.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
