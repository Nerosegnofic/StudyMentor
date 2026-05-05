import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../data/providers/dataconnect_provider.dart';
import '../../../services/friend_code_service.dart';
import 'student_settings.dart';
import 'student_help_center.dart';

class StudentProfile extends StatefulWidget {
  final String fullName;
  final String uid;

  const StudentProfile({
    super.key,
    required this.fullName,
    required this.uid,
  });

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  String? _friendCode;
  bool _codeLoading = true;

  static const int _placeholderXp = 1000;
  static const int _placeholderStreak = 10;
  static const int _placeholderQuestions = 200;
  static const int _placeholderLevel = 2;
  static const String _placeholderRank = 'Master Gardener';

  @override
  void initState() {
    super.initState();
    _loadFriendCode();
  }

  Future<void> _loadFriendCode() async {
    try {
      final service = FriendCodeService(DataConnectProvider());
      final code = await service.getOrCreate(widget.uid, widget.fullName);
      if (mounted) setState(() => _friendCode = code);
    } catch (_) {
      if (mounted) setState(() => _friendCode = _generateFallback());
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  String _generateFallback() {
    final first = widget.fullName.trim().split(RegExp(r'\s+')).first;
    final letters =
        first.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix =
        letters.length >= 4 ? letters.substring(0, 4) : letters.padRight(4, 'X');
    return '$prefix-0000';
  }

  void _copyCode() {
    if (_friendCode == null) return;
    Clipboard.setData(ClipboardData(text: _friendCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend code copied!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildProgressCard(),
                const SizedBox(height: 14),
                _buildFriendCodeCard(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: avatar + level badge + name + rank pill ──────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 28, bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FF),
      ),
      child: Column(
        children: [
          _buildAvatarWithBadge(),
          const SizedBox(height: 14),
          Text(
            widget.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          _buildRankPill(),
        ],
      ),
    );
  }

  Widget _buildAvatarWithBadge() {
    final initial = widget.fullName.isNotEmpty
        ? widget.fullName[0].toUpperCase()
        : '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                'Level $_placeholderLevel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Color(0xFFFF8F00), size: 15),
          const SizedBox(width: 4),
          Text(
            _placeholderRank,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF8F00),
            ),
          ),
        ],
      ),
    );
  }

  // ── My Progress card ─────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Progress',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  icon: Icons.auto_awesome,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFFFB300),
                  value: _formatNumber(_placeholderXp),
                  label: 'Total XP',
                ),
              ),
              Expanded(
                child: _buildStat(
                  icon: Icons.local_fire_department,
                  iconBg: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFF44336),
                  value: '$_placeholderStreak',
                  label: 'Day Streak',
                ),
              ),
              Expanded(
                child: _buildStat(
                  icon: Icons.check_circle_outline,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF43A047),
                  value: '$_placeholderQuestions',
                  label: 'Questions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // ── Friend Code card ─────────────────────────────────────────────────────

  Widget _buildFriendCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Friend Code',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Copy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _codeLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    _friendCode ?? '—',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
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

  // ── Settings section ─────────────────────────────────────────────────────

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsRow(
                icon: Icons.settings_outlined,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1E88E5),
                title: 'App Settings',
                subtitle: 'Notifications, Sound',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentSettings(uid: widget.uid),
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 60,
                color: Colors.grey.shade100,
              ),
              _buildSettingsRow(
                icon: Icons.help_outline,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1E88E5),
                title: 'Help & Support',
                subtitle: 'Get help or report issues',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentHelpCenter(
                      uid: widget.uid,
                      fullName: widget.fullName,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Log Out button ───────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(
          StudentLogoutVerificationRequested(studentUid: widget.uid),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.grey.shade700,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final whole = n ~/ 1000;
      final remainder = (n % 1000).toString().padLeft(3, '0');
      return '$whole,$remainder';
    }
    return '$n';
  }
}
