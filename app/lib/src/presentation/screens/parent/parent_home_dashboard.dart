import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../data/providers/dataconnect_provider.dart';
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
  final _provider = DataConnectProvider();

  // ── Friend-request state ──────────────────────────────────────────────────
  bool _requestsLoading = true;
  String? _requestsError;
  List<Map<String, dynamic>> _friendRequests = [];
  final Set<String> _processing = {};
  List<StudentModel> _realStudents = [];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is StudentsLoaded) {
      _realStudents = authState.students;
    }
    context.read<AuthBloc>().add(
          LoadStudentsRequested(parentUid: widget.parentUid),
        );
    _loadRequests();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _requestsLoading = true;
      _requestsError = null;
    });
    try {
      final data = await _provider.getPendingFriendRequestsForParent(
        widget.parentUid,
      );
      if (mounted) setState(() => _friendRequests = data);
    } catch (e) {
      if (mounted) setState(() => _requestsError = e.toString());
    } finally {
      if (mounted) setState(() => _requestsLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    context.read<AuthBloc>().add(
          LoadStudentsRequested(parentUid: widget.parentUid),
        );
    await _loadRequests();
  }

  // ── Friend-request actions ────────────────────────────────────────────────

  Future<void> _approve(Map<String, dynamic> req) async {
    final id = req['id'] as String;
    final fromUid = req['from_student_uid'] as String;
    final toUid = req['to_student_uid'] as String;

    setState(() => _processing.add(id));
    try {
      await Future.wait([
        _provider.createFriendship(studentUid: fromUid, friendUid: toUid),
        _provider.createFriendship(studentUid: toUid, friendUid: fromUid),
      ]);
      await _provider.updateFriendRequestStatus(id: id, status: 'accepted');
      if (mounted) {
        setState(() => _friendRequests.removeWhere((r) => r['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${req['from_student_name']} and ${req['to_student_name']} are now friends!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final id = req['id'] as String;
    setState(() => _processing.add(id));
    try {
      await _provider.updateFriendRequestStatus(id: id, status: 'rejected');
      if (mounted) {
        setState(() => _friendRequests.removeWhere((r) => r['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  // ── Navigation to real child config ──────────────────────────────────────

  Future<void> _openConfig(StudentModel student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: StudentProfileDashboard(student: student),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
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
                      child: BrandedHeader(parentName: widget.fullName),
                    ),
                  ),

                  // Component 2 — "My Children" subheader
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
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

                  // Component 4 — AI Summary Carousel
                  const SliverToBoxAdapter(child: AiSummaryCarousel()),

                  // ── Friend Requests section (preserved logic) ─────────
                  if (_requestsLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_requestsError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          'Could not load approvals: $_requestsError',
                          style: GoogleFonts.roboto(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else if (_friendRequests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 24,
                          left: 20,
                          bottom: 12,
                        ),
                        child: Text(
                          'Pending Approvals',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final req = _friendRequests[i];
                            return _FriendRequestCard(
                              request: req,
                              isProcessing: _processing.contains(req['id']),
                              onApprove: () => _approve(req),
                              onReject: () => _reject(req),
                            );
                          },
                          childCount: _friendRequests.length,
                        ),
                      ),
                    ),
                  ],

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

// ── Friend Request Card ───────────────────────────────────────────────────────

class _FriendRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _FriendRequestCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = request['from_student_name'] as String;
    final toName = request['to_student_name'] as String;
    final createdAt = request['created_at'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(
                  fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: fromName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' wants to add '),
                          TextSpan(
                            text: toName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' as a friend'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(createdAt),
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isProcessing)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2196F3),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Reject',
                        style: GoogleFonts.roboto(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Approve',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
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
