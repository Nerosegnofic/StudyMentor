import 'package:flutter/material.dart';
import '../../../data/providers/dataconnect_provider.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _LeaderboardEntry {
  final String uid;
  // ── CHANGED: username replaces fullName (leaderboard shows username) ───────
  final String username;
  final int weeklyXp;
  final int totalXp;
  final DateTime? lastActiveAt;

  _LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.weeklyXp,
    required this.totalXp,
    this.lastActiveAt,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class StudentLeaderboard extends StatefulWidget {
  final String uid;
  final String fullName;

  const StudentLeaderboard({
    super.key,
    required this.uid,
    required this.fullName,
  });

  @override
  State<StudentLeaderboard> createState() => _StudentLeaderboardState();
}

class _StudentLeaderboardState extends State<StudentLeaderboard> {
  List<_LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await DataConnectProvider().getWeeklyLeaderboard();
      setState(() {
        _entries = raw
            .map(
              (r) => _LeaderboardEntry(
                uid: r['uid'] as String,
                // ── CHANGED: read username instead of full_name ────────────
                username: r['username'] as String,
                weeklyXp: r['weekly_xp'] as int,
                totalXp: r['total_xp'] as int,
                lastActiveAt: r['last_active_at'] as DateTime?,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_entries.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildList() {
    final top3 = _entries.take(3).toList();
    final rest = _entries.skip(3).toList();
    final myIndex = _entries.indexWhere((e) => e.uid == widget.uid);

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildPodium(top3)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < rest.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                          indent: 60,
                        ),
                      _buildRow(rest[i], i + 4),
                    ],
                    if (myIndex > rest.length + 2) ...[
                      Divider(height: 1, color: Colors.grey.shade100),
                      _buildRow(_entries[myIndex], myIndex + 1, isMe: true),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildPodium(List<_LeaderboardEntry> top) {
    if (top.isEmpty) return const SizedBox.shrink();
    final first = top[0];
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second != null
                ? _buildPodiumPlace(second, 2, 72)
                : const SizedBox(),
          ),
          Expanded(child: _buildPodiumPlace(first, 1, 92, isCenter: true)),
          Expanded(
            child: third != null
                ? _buildPodiumPlace(third, 3, 64)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  static const _podiumColors = [
    null,
    (
      base: Color(0xFFFFB300),
      light: Color(0xFFFFF8E1),
      pedestal: Color(0xFFFF8F00),
    ),
    (
      base: Color(0xFF9E9E9E),
      light: Color(0xFFF5F5F5),
      pedestal: Color(0xFF757575),
    ),
    (
      base: Color(0xFF8D6E63),
      light: Color(0xFFEFEBE9),
      pedestal: Color(0xFF6D4C41),
    ),
  ];

  Widget _buildPodiumPlace(
    _LeaderboardEntry entry,
    int place,
    double avatarSize, {
    bool isCenter = false,
  }) {
    final c = _podiumColors[place]!;
    // ── CHANGED: initial from username ─────────────────────────────────────
    final initial = entry.username.isNotEmpty
        ? entry.username[0].toUpperCase()
        : '?';
    final isMe = entry.uid == widget.uid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCenter) ...[
          Icon(Icons.workspace_premium, color: c.base, size: 24),
          const SizedBox(height: 4),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: isMe
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF7B1FA2),
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: avatarSize * 0.36,
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.base,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$place',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── CHANGED: display username ──────────────────────────────────────
        Text(
          entry.username,
          style: TextStyle(
            fontSize: isCenter ? 13 : 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.light,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: c.base, size: 11),
              const SizedBox(width: 3),
              Text(
                '${entry.weeklyXp}',
                style: TextStyle(
                  color: c.base,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: isCenter ? 60 : (place == 2 ? 46 : 36),
          decoration: BoxDecoration(
            color: c.pedestal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: Center(
            child: Icon(
              place == 1 ? Icons.workspace_premium : Icons.military_tech,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_LeaderboardEntry entry, int rank, {bool isMe = false}) {
    // ── CHANGED: initial from username ─────────────────────────────────────
    final initial = entry.username.isNotEmpty
        ? entry.username[0].toUpperCase()
        : '?';
    final me = isMe || entry.uid == widget.uid;

    return Container(
      color: me ? const Color(0xFFE3F2FD) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: me ? const Color(0xFF1565C0) : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: me
                ? const Color(0xFF1565C0)
                : const Color(0xFF7B1FA2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // ── CHANGED: display username ────────────────────────────────
            child: Text(
              me ? '${entry.username} (You)' : entry.username,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: me ? const Color(0xFF1565C0) : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: me ? const Color(0xFF1565C0) : const Color(0xFFFFB300),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.weeklyXp}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: me ? const Color(0xFF1565C0) : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        8,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load leaderboard'),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text('No students on the leaderboard yet.'));
  }
}
