import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandedHeader extends StatelessWidget {
  final String parentName;

  const BrandedHeader({super.key, required this.parentName});

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Flat rectangle — no border-radius. Shadow cast downward so scrolled
      // content visibly slides under the sticky header.
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // soft dark shadow on bottom edge
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: 28.0,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Circular profile avatar (50x50px)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // Center: "Study Mentor" — Cairo Bold, white, 24px
            Text(
              'Study Mentor',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.3,
              ),
            ),

            // Right: Bell icon with red notification dot
            GestureDetector(
              onTap: () => _showNotificationsSheet(context),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2196F3),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications Bottom Sheet ──────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // List
            const _NotificationItem(
              iconBg: Color(0xFFE3F2FD),
              iconColor: Color(0xFF2196F3),
              icon: Icons.check_circle_rounded,
              title: 'Screen Time Unlocked',
              subtitle: 'Ahmed earned 15 mins for passing Mathematics.',
              time: '2m ago',
            ),
            const _NotificationItem(
              iconBg: Color(0xFFFFEBEE),
              iconColor: Color(0xFFE53935),
              icon: Icons.warning_rounded,
              title: 'Needs Work',
              subtitle: 'Ahmed scored 45% on Decimals.',
              time: '1h ago',
            ),
            const _NotificationItem(
              iconBg: Color(0xFFF1F5F9),
              iconColor: Color(0xFF64748B),
              icon: Icons.system_update_rounded,
              title: 'System Update',
              subtitle: 'New science quizzes are available.',
              time: 'Yesterday',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            time,
            style: GoogleFonts.roboto(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
