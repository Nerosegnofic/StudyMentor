import 'package:flutter/material.dart';
import '../../../data/providers/dataconnect_provider.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _LeaderboardEntry {
  final String uid;
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

// ─── Enums ────────────────────────────────────────────────────────────────────

enum _LeaderboardMode { siblings, global, friends }

enum _TimeRange { weekly, allTime }

// ─── Main Screen ──────────────────────────────────────────────────────────────

class StudentLeaderboard extends StatefulWidget {
  final String uid;
  final String fullName;
  final String parentUid;

  const StudentLeaderboard({
    super.key,
    required this.uid,
    required this.fullName,
    required this.parentUid,
  });

  @override
  State<StudentLeaderboard> createState() => _StudentLeaderboardState();
}

class _StudentLeaderboardState extends State<StudentLeaderboard> {
  _LeaderboardMode _mode = _LeaderboardMode.global;
  _TimeRange _timeRange = _TimeRange.weekly;

  // Cached data per mode (raw, unfiltered)
  List<_LeaderboardEntry> _globalEntries = [];
  List<_LeaderboardEntry> _siblingEntries = [];
  List<_LeaderboardEntry> _friendsEntries = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StudentLeaderboard old) {
    super.didUpdateWidget(old);
    // Reload when parentUid becomes available (initially empty).
    if (old.parentUid != widget.parentUid && widget.parentUid.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = DataConnectProvider();

      // Always load global; load siblings only if parentUid is available.
      final futures = <Future>[
        provider.getWeeklyLeaderboard(),
        provider.getFriendsForStudent(widget.uid),
        if (widget.parentUid.isNotEmpty)
          provider.getSiblingLeaderboard(widget.parentUid),
      ];

      final results = await Future.wait(futures);

      final globalRaw = results[0] as List<Map<String, dynamic>>;
      final friendsRaw = results[1] as List<Map<String, dynamic>>;
      final siblingRaw = widget.parentUid.isNotEmpty
          ? results[2] as List<Map<String, dynamic>>
          : <Map<String, dynamic>>[];

      // Build self-entry from global list.
      _LeaderboardEntry? selfEntry;
      for (final r in globalRaw) {
        if (r['uid'] == widget.uid) {
          selfEntry = _LeaderboardEntry(
            uid: r['uid'] as String,
            username: r['username'] as String,
            weeklyXp: r['weekly_xp'] as int,
            totalXp: r['total_xp'] as int,
            lastActiveAt: r['last_active_at'] as DateTime?,
          );
          break;
        }
      }

      setState(() {
        _globalEntries = globalRaw
            .map(
              (r) => _LeaderboardEntry(
                uid: r['uid'] as String,
                username: r['username'] as String,
                weeklyXp: r['weekly_xp'] as int,
                totalXp: r['total_xp'] as int,
                lastActiveAt: r['last_active_at'] as DateTime?,
              ),
            )
            .toList();

        // Friends: friends + self
        final friendsList = friendsRaw
            .map(
              (r) => _LeaderboardEntry(
                uid: r['friend_uid'] as String,
                username: r['username'] as String,
                weeklyXp: r['weekly_xp'] as int,
                totalXp: r['total_xp'] as int,
                lastActiveAt: r['last_active_at'] as DateTime?,
              ),
            )
            .toList();
        if (selfEntry != null &&
            !friendsList.any((e) => e.uid == widget.uid)) {
          friendsList.add(selfEntry);
        }
        _friendsEntries = friendsList;

        _siblingEntries = siblingRaw
            .map(
              (r) => _LeaderboardEntry(
                uid: r['uid'] as String,
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

  // ── Current list (sorted by selected time range) ──────────────────────────

  List<_LeaderboardEntry> get _currentEntries {
    final raw = switch (_mode) {
      _LeaderboardMode.global => _globalEntries,
      _LeaderboardMode.friends => _friendsEntries,
      _LeaderboardMode.siblings => _siblingEntries,
    };

    final sorted = List<_LeaderboardEntry>.from(raw);
    if (_timeRange == _TimeRange.allTime) {
      sorted.sort((a, b) {
        final xpCmp = b.totalXp.compareTo(a.totalXp);
        return xpCmp != 0 ? xpCmp : b.weeklyXp.compareTo(a.weeklyXp);
      });
    } else {
      sorted.sort((a, b) {
        final xpCmp = b.weeklyXp.compareTo(a.weeklyXp);
        return xpCmp != 0 ? xpCmp : b.totalXp.compareTo(a.totalXp);
      });
    }
    return sorted;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModeSelector(),
        _buildTimeRangeToggle(),
        Expanded(
          child: _loading
              ? _buildSkeleton()
              : _error != null
              ? _buildError()
              : _currentEntries.isEmpty
              ? _buildEmpty()
              : _buildList(_currentEntries),
        ),
      ],
    );
  }

  // ── Mode selector ─────────────────────────────────────────────────────────

  static const _modeLabels = {
    _LeaderboardMode.siblings: ('Siblings', Icons.family_restroom_rounded),
    _LeaderboardMode.global: ('Global', Icons.public_rounded),
    _LeaderboardMode.friends: ('Friends', Icons.people_rounded),
  };

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _LeaderboardMode.values.map((mode) {
          final (label, icon) = _modeLabels[mode]!;
          final selected = _mode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF4A6CF7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: selected ? Colors.white : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Time range toggle ─────────────────────────────────────────────────────

  Widget _buildTimeRangeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _buildToggleChip(
            label: 'This Week',
            icon: Icons.calendar_today_rounded,
            selected: _timeRange == _TimeRange.weekly,
            onTap: () => setState(() => _timeRange = _TimeRange.weekly),
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: 'All Time',
            icon: Icons.emoji_events_rounded,
            selected: _timeRange == _TimeRange.allTime,
            onTap: () => setState(() => _timeRange = _TimeRange.allTime),
          ),
          const Spacer(),
          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4A6CF7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4A6CF7)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? const Color(0xFF4A6CF7) : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF4A6CF7)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(List<_LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();
    final myIndex = entries.indexWhere((e) => e.uid == widget.uid);

    return RefreshIndicator(
      color: const Color(0xFF4A6CF7),
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
                    // Sticky "my rank" row if I'm outside visible range.
                    if (myIndex > rest.length + 2) ...[
                      Divider(height: 1, color: Colors.grey.shade100),
                      _buildRow(entries[myIndex], myIndex + 1, isMe: true),
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

  // ── Podium ────────────────────────────────────────────────────────────────

  Widget _buildPodium(List<_LeaderboardEntry> top) {
    if (top.isEmpty) return const SizedBox.shrink();
    final first = top[0];
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
    final initial = entry.username.isNotEmpty
        ? entry.username[0].toUpperCase()
        : '?';
    final isMe = entry.uid == widget.uid;
    final xpValue = _timeRange == _TimeRange.weekly
        ? entry.weeklyXp
        : entry.totalXp;

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
                '$xpValue',
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

  // ── Row ───────────────────────────────────────────────────────────────────

  Widget _buildRow(_LeaderboardEntry entry, int rank, {bool isMe = false}) {
    final initial = entry.username.isNotEmpty
        ? entry.username[0].toUpperCase()
        : '?';
    final me = isMe || entry.uid == widget.uid;
    final xpValue = _timeRange == _TimeRange.weekly
        ? entry.weeklyXp
        : entry.totalXp;

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
                '$xpValue',
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

  // ── States ────────────────────────────────────────────────────────────────

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
    final label = switch (_mode) {
      _LeaderboardMode.siblings => 'No siblings to compare yet.',
      _LeaderboardMode.friends => 'Add friends to see them here.',
      _LeaderboardMode.global => 'No students on the leaderboard yet.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
