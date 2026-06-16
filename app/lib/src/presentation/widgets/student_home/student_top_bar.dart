import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/avatar_config.dart';
import '../avatar_widget.dart';

/// Student full-screen top bar — a flat green gradient band matching the
/// profile/settings headers (no BottomNavigationBar per the design system).
///
/// Navigation is contextual: tap the avatar → profile; the coins pill is the
/// shop button (coin + balance + cart + chevron) → shop. The notification bell
/// is a plain white icon with a small amber dot (no container/chip).
class StudentTopBar extends StatelessWidget {
  final AvatarConfig avatarConfig;
  final int level;
  final int coins;

  /// Shows the amber notification dot when true.
  final bool hasNotifications;

  final VoidCallback onAvatarTap;
  final VoidCallback onCoinsTap;
  final VoidCallback onNotificationsTap;

  const StudentTopBar({
    super.key,
    required this.avatarConfig,
    required this.level,
    required this.coins,
    this.hasNotifications = true,
    required this.onAvatarTap,
    required this.onCoinsTap,
    required this.onNotificationsTap,
  });

  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenDark = Color(0xFF43A047);
  static const Color _amber = Color(0xFFFFC107);
  static const Color _coinInk = Color(0xFFF57F17);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_greenDark, _green],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 14),
      child: Row(
        children: [
          _avatarButton(),
          const Spacer(),
          _levelPill(),
          const SizedBox(width: 8),
          _shopButton(),
          const SizedBox(width: 12),
          _bell(),
        ],
      ),
    );
  }

  Widget _avatarButton() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(child: AvatarWidget(config: avatarConfig, size: 44.0)),
      ),
    );
  }

  Widget _levelPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _amber, size: 16),
          const SizedBox(width: 4),
          Text(
            'Lv. $level',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// Coins pill that doubles as the shop entry: coin + balance + cart + chevron.
  Widget _shopButton() {
    return GestureDetector(
      onTap: onCoinsTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              _formatNum(coins),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _coinInk,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 14, color: const Color(0xFFFFE082)),
            const SizedBox(width: 6),
            const Icon(Icons.shopping_cart_rounded, size: 14, color: _coinInk),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: _coinInk.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _bell() {
    return GestureDetector(
      onTap: onNotificationsTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
          if (hasNotifications)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: _amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final thousands = s.substring(0, s.length - 3);
      final remainder = s.substring(s.length - 3);
      return '$thousands,$remainder';
    }
    return '$n';
  }
}