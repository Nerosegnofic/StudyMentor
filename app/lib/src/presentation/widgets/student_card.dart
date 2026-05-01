// lib/src/presentation/widgets/student_card.dart
//
// Displays a single student with two distinct visual states:
//
//   • Unverified — darkened card, desaturated avatar, red "UNVERIFIED" badge,
//     tapping does nothing.
//   • Verified   — full-colour card, normal appearance, tapping does nothing
//     yet (future feature hook provided via [onTap]).

import 'package:flutter/material.dart';
import '../../domain/models/student_model.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;

  /// Called when the card is tapped AND the student is verified.
  /// Leave null until card-interaction functionality is implemented.
  final VoidCallback? onTap;

  const StudentCard({super.key, required this.student, this.onTap});

  // ── colour palette ──────────────────────────────────────────────────────────

  static const _verifiedPrimary = Color(0xFF4A6CF7);
  static const _verifiedAvatarBg = Color(0xFFE8EDFF);
  static const _verifiedAvatarFg = Color(0xFF4A6CF7);
  static const _verifiedXpColor = Color(0xFF34A853);

  static const _unverifiedCardBg = Color(0xFF2A2A2A);
  static const _unverifiedAvatarBg = Color(0xFF3D3D3D);
  static const _unverifiedAvatarFg = Color(0xFF757575);
  static const _unverifiedTextPrimary = Color(0xFF9E9E9E);
  static const _unverifiedTextSecondary = Color(0xFF616161);

  // ── helpers ─────────────────────────────────────────────────────────────────

  String get _initials {
    final parts = student.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return student.fullName.isNotEmpty
        ? student.fullName[0].toUpperCase()
        : '?';
  }

  String get _gradeLabel =>
      student.gradeLevel != null ? 'Grade ${student.gradeLevel}' : 'No grade';

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final verified = student.isEmailVerified;

    return GestureDetector(
      onTap: verified ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: verified ? Colors.white : _unverifiedCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: verified
              ? [
                  BoxShadow(
                    color: _verifiedPrimary.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: verified
              ? Border.all(color: const Color(0xFFE8EDFF), width: 1.5)
              : Border.all(color: const Color(0xFF3A3A3A), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAvatar(verified),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInfo(verified)),
                  const SizedBox(width: 8),
                  _buildStats(verified),
                ],
              ),
            ),
            if (!verified) _buildUnverifiedBadge(),
          ],
        ),
      ),
    );
  }

  // ── avatar ──────────────────────────────────────────────────────────────────

  Widget _buildAvatar(bool verified) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: verified ? _verifiedAvatarBg : _unverifiedAvatarBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: verified ? _verifiedAvatarFg : _unverifiedAvatarFg,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ── name / email / grade ────────────────────────────────────────────────────

  Widget _buildInfo(bool verified) {
    final nameColor = verified
        ? const Color(0xFF1A1A2E)
        : _unverifiedTextPrimary;
    final emailColor = verified
        ? const Color(0xFF8B93A7)
        : _unverifiedTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          student.fullName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: nameColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          student.email,
          style: TextStyle(fontSize: 12, color: emailColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildGradeChip(verified),
      ],
    );
  }

  Widget _buildGradeChip(bool verified) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: verified ? const Color(0xFFE8EDFF) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 11,
            color: verified ? _verifiedPrimary : _unverifiedTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _gradeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: verified ? _verifiedPrimary : _unverifiedTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── XP / coins stats ────────────────────────────────────────────────────────

  Widget _buildStats(bool verified) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatPill(
          icon: Icons.bolt,
          value: '${student.totalXp ?? 0} XP',
          iconColor: verified ? _verifiedXpColor : _unverifiedTextSecondary,
          textColor: verified
              ? const Color(0xFF1A1A2E)
              : _unverifiedTextPrimary,
          bgColor: verified ? const Color(0xFFE6F4EA) : const Color(0xFF333333),
        ),
        const SizedBox(height: 6),
        _buildStatPill(
          icon: Icons.monetization_on_outlined,
          value: '${student.totalCoins ?? 0}',
          iconColor: verified
              ? const Color(0xFFFFB300)
              : _unverifiedTextSecondary,
          textColor: verified
              ? const Color(0xFF1A1A2E)
              : _unverifiedTextPrimary,
          bgColor: verified ? const Color(0xFFFFF8E1) : const Color(0xFF333333),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required Color iconColor,
    required Color textColor,
    required Color bgColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── UNVERIFIED badge ────────────────────────────────────────────────────────

  Widget _buildUnverifiedBadge() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 11,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              'UNVERIFIED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
