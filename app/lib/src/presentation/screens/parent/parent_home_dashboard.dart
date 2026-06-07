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
                          'My Children',
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
