import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/notifications/notifications_bloc.dart';
import '../../../bloc/notifications/notifications_event.dart';
import '../../../bloc/notifications/notifications_state.dart';
import '../../../domain/models/notification_model.dart';
import '../../screens/parent/parent_account_screen.dart';
import '../../../../l10n/app_localizations.dart';

class BrandedHeader extends StatefulWidget {
  final String parentName;
  final String parentUid;

  const BrandedHeader({
    super.key,
    required this.parentName,
    required this.parentUid,
  });

  @override
  State<BrandedHeader> createState() => _BrandedHeaderState();
}

class _BrandedHeaderState extends State<BrandedHeader> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(LoadNotificationsRequested(widget.parentUid));
  }

  void _showNotificationsSheet(BuildContext context, List<NotificationModel> notifications) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsSheet(
        notifications: notifications,
        parentUid: widget.parentUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        List<NotificationModel> notifications = [];
        if (state is NotificationsLoaded) {
          notifications = state.notifications;
        }
        
        final hasUnread = notifications.any((n) => !n.isRead);

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
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ParentAccountScreen(),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.parentName.isNotEmpty ? widget.parentName[0].toUpperCase() : 'P',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
              onTap: () => _showNotificationsSheet(context, notifications),
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
                    if (hasUnread)
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
      },
    );
  }
}

// ── Notifications Bottom Sheet ──────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  final List<NotificationModel> notifications;
  final String parentUid;

  const _NotificationsSheet({
    required this.notifications,
    required this.parentUid,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                    loc.notificationsTitle,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(MarkAllNotificationsReadRequested(parentUid));
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      loc.markAllAsReadButton,
                      style: const TextStyle(
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
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.allCaughtUpTitle,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.allCaughtUpMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...notifications.map((notif) {
                IconData icon;
                Color iconColor;
                Color iconBg;

                switch (notif.type) {
                  case NotificationType.screenTimeUnlocked:
                    icon = Icons.check_circle_rounded;
                    iconColor = const Color(0xFF2196F3);
                    iconBg = const Color(0xFFE3F2FD);
                    break;
                  case NotificationType.needsWork:
                    icon = Icons.warning_rounded;
                    iconColor = const Color(0xFFE53935);
                    iconBg = const Color(0xFFFFEBEE);
                    break;
                  case NotificationType.systemUpdate:
                    icon = Icons.system_update_rounded;
                    iconColor = const Color(0xFF64748B);
                    iconBg = const Color(0xFFF1F5F9);
                    break;
                  case NotificationType.streakAchieved:
                    icon = Icons.local_fire_department_rounded;
                    iconColor = const Color(0xFFFF9800);
                    iconBg = const Color(0xFFFFF3E0);
                    break;
                }

                // Simple time formatter
                final diff = DateTime.now().difference(notif.createdAt);
                String timeStr;
                if (diff.inMinutes < 60) {
                  timeStr = loc.minutesAgoLabel(diff.inMinutes);
                } else if (diff.inHours < 24) {
                  timeStr = loc.hoursAgoLabel(diff.inHours);
                } else {
                  timeStr = loc.daysAgoLabel(diff.inDays);
                }

                return _NotificationItem(
                  iconBg: iconBg,
                  iconColor: iconColor,
                  icon: icon,
                  title: notif.title,
                  subtitle: notif.subtitle,
                  time: timeStr,
                  isRead: notif.isRead,
                );
              }),
            ],
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
  final bool isRead;

  const _NotificationItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
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
                  style: GoogleFonts.cairo(
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
            style: GoogleFonts.cairo(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
