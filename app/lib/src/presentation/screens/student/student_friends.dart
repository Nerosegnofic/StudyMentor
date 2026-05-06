import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/providers/dataconnect_provider.dart';
import '../../../utils/student_rank_utils.dart';
import '../../../services/friend_code_service.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class _FriendEntry {
  final String friendshipId;
  final String uid;
  final String fullName;
  final int totalXp;
  final DateTime? lastActiveAt;

  int get level => StudentRankUtils.levelFromXp(totalXp);
  String get rank => StudentRankUtils.rankFromLevel(level);
  bool get online => StudentRankUtils.isOnline(lastActiveAt);

  _FriendEntry({
    required this.friendshipId,
    required this.uid,
    required this.fullName,
    required this.totalXp,
    this.lastActiveAt,
  });
}

class _SentRequest {
  final String id;
  final String toStudentName;
  final String toFriendCode;
  final String status;
  final DateTime createdAt;

  _SentRequest({
    required this.id,
    required this.toStudentName,
    required this.toFriendCode,
    required this.status,
    required this.createdAt,
  });
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class StudentFriends extends StatefulWidget {
  final String uid;
  final String fullName;

  const StudentFriends({super.key, required this.uid, required this.fullName});

  @override
  State<StudentFriends> createState() => _StudentFriendsState();
}

class _StudentFriendsState extends State<StudentFriends>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab selector ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'My Friends'),
                Tab(text: 'Add Friend'),
              ],
            ),
          ),
        ),
        // ── Tab bodies ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FriendsTab(
                myUid: widget.uid,
                onAddFriendTap: () => _tabController.animateTo(1),
              ),
              _AddFriendTab(myUid: widget.uid, myFullName: widget.fullName),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: My Friends ────────────────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  final String myUid;
  final VoidCallback onAddFriendTap;
  const _FriendsTab({required this.myUid, required this.onAddFriendTap});

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_FriendEntry> _friends = [];
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
      final raw = await DataConnectProvider().getFriendsForStudent(
        widget.myUid,
      );
      setState(() {
        _friends = raw
            .map(
              (r) => _FriendEntry(
                friendshipId: r['friendship_id'] as String,
                uid: r['friend_uid'] as String,
                fullName: r['full_name'] as String,
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

  Future<void> _removeFriend(_FriendEntry friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend.fullName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(
      () => _friends.removeWhere((f) => f.friendshipId == friend.friendshipId),
    );
    try {
      await DataConnectProvider().removeFriend(friend.friendshipId);
    } catch (_) {
      if (mounted) {
        setState(() => _friends.add(friend));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove friend. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_friends.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              const Text(
                'My Friends',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF2E7D32),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_friends.length}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stay connected with your study buddies!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          for (final f in _friends)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFriendCard(f),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(_FriendEntry friend) {
    final initial = friend.fullName.isNotEmpty
        ? friend.fullName[0].toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7B1FA2).withOpacity(0.85),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: friend.online
                        ? const Color(0xFF2196F3)
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      friend.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (friend.online) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  friend.rank,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${friend.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFriend(friend),
            icon: Icon(
              Icons.delete_outline,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
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
          const Text('Could not load friends'),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No friends yet!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends using their friend code to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onAddFriendTap,
              icon: const Icon(Icons.person_add),
              label: const Text('Add a Friend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Add Friend ────────────────────────────────────────────────────────

class _AddFriendTab extends StatefulWidget {
  final String myUid;
  final String myFullName;
  const _AddFriendTab({required this.myUid, required this.myFullName});

  @override
  State<_AddFriendTab> createState() => _AddFriendTabState();
}

class _AddFriendTabState extends State<_AddFriendTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  String? _myFriendCode;
  bool _codeLoading = true;
  bool _sending = false;

  List<_SentRequest> _sentRequests = [];
  bool _requestsLoading = true;

  static final _codeRegex = RegExp(r'^[A-Z]+-\d{4}$');
  bool get _isValid => _codeRegex.hasMatch(_codeController.text.trim());

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = DataConnectProvider();
    final results = await Future.wait([
      FriendCodeService(provider).getOrCreate(widget.myUid, widget.myFullName),
      provider.getSentFriendRequests(widget.myUid),
    ]);
    if (!mounted) return;
    setState(() {
      _myFriendCode = results[0] as String;
      _codeLoading = false;
      final raw = results[1] as List<Map<String, dynamic>>;
      _sentRequests = raw
          .map(
            (r) => _SentRequest(
              id: r['id'] as String,
              toStudentName: r['to_student_name'] as String,
              toFriendCode: r['to_friend_code'] as String,
              status: r['status'] as String,
              createdAt: r['created_at'] as DateTime,
            ),
          )
          .toList();
      _requestsLoading = false;
    });
  }

  Future<void> _sendRequest() async {
    final code = _codeController.text.trim().toUpperCase();
    if (!_isValid || _sending) return;

    if (code == _myFriendCode) {
      _showSnack("You can't add yourself!");
      return;
    }
    if (_sentRequests.any((r) => r.toFriendCode == code)) {
      _showSnack('You already sent a request to this code.');
      return;
    }

    setState(() => _sending = true);
    try {
      final provider = DataConnectProvider();
      final target = await provider.getStudentByFriendCode(code);
      if (target == null) {
        _showSnack('No student found with that code.');
        return;
      }
      final targetUid = target['uid'] as String;
      final targetName = target['full_name'] as String;

      await provider.sendFriendRequest(
        fromStudentUid: widget.myUid,
        toFriendCode: code,
        toStudentUid: targetUid,
        toStudentName: targetName,
      );

      if (mounted) {
        setState(() {
          _sentRequests.insert(
            0,
            _SentRequest(
              id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
              toStudentName: targetName,
              toFriendCode: code,
              status: 'pending_parent_approval',
              createdAt: DateTime.now(),
            ),
          );
          _codeController.clear();
        });
        _showSnack('Request sent to $targetName!');
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to send request. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyCode() {
    if (_myFriendCode == null) return;
    Clipboard.setData(ClipboardData(text: _myFriendCode!));
    _showSnack('Friend code copied!');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSafeSecureBanner(),
          const SizedBox(height: 14),
          _buildEnterCodeCard(),
          const SizedBox(height: 20),
          _buildSentRequests(),
          const SizedBox(height: 20),
          _buildMyCodeCard(),
        ],
      ),
    );
  }

  Widget _buildSafeSecureBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2E7D32),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe & Secure',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your parent must approve new friends before they appear on your list.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Friend Code',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            focusNode: _codeFocus,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              TextInputFormatter.withFunction((old, newVal) {
                final upper = newVal.text.toUpperCase();
                return newVal.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }),
            ],
            decoration: InputDecoration(
              hintText: 'e.g., AHMED-1234',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              helperText: 'Ask your friend for their unique code',
              helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid && !_sending ? _sendRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sent Requests',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        if (_requestsLoading)
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          )
        else if (_sentRequests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No sent requests yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          for (final req in _sentRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRequestCard(req),
            ),
      ],
    );
  }

  Widget _buildRequestCard(_SentRequest req) {
    final initial = req.toStudentName.isNotEmpty
        ? req.toStudentName[0].toUpperCase()
        : '?';
    final days = DateTime.now().difference(req.createdAt).inDays;
    final daysAgo = days == 0
        ? 'Today'
        : days == 1
        ? '1 day ago'
        : '$days days ago';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF7B1FA2).withOpacity(0.85),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.toStudentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Sent $daysAgo',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Color(0xFFFF8F00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        req.status == 'pending_parent_approval'
                            ? 'Waiting for Parent Approval'
                            : req.status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Your Friend Code',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _codeLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _myFriendCode ?? '—',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Share this code with friends so they can add you!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
