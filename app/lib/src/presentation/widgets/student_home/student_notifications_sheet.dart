import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../bloc/notifications/notifications_bloc.dart';
import '../../../bloc/notifications/notifications_event.dart';
import '../../../bloc/notifications/notifications_state.dart';
import '../../../domain/models/notification_model.dart';

/// Student notifications bottom sheet.
///
/// Sources rows live from [NotificationsBloc]. Each row has a toggle-read
/// button and a delete button that dispatch optimistic BLoC events.
class StudentNotificationsSheet extends StatelessWidget {
  final String studentUid;

  const StudentNotificationsSheet({super.key, required this.studentUid});

  static const Color _green = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final notifications =
            state is NotificationsLoaded ? state.notifications : <NotificationModel>[];
        return _buildSheet(context, notifications);
      },
    );
  }

  Widget _buildSheet(BuildContext context, List<NotificationModel> notifications) {
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
                      context
                          .read<NotificationsBloc>()
                          .add(MarkAllStudentNotificationsReadRequested(studentUid));
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      loc.markAllAsReadButton,
                      style: const TextStyle(
                        color: _green,
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
                    iconColor = const Color(0xFF4CAF50);
                    iconBg = const Color(0xFFE8F5E9);
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
                  onToggleRead: () {
                    context.read<NotificationsBloc>().add(
                          ToggleStudentNotificationReadRequested(
                            notif.id,
                            isRead: !notif.isRead,
                          ),
                        );
                  },
                  onDelete: () {
                    context.read<NotificationsBloc>().add(
                          DeleteStudentNotificationRequested(notif.id),
                        );
                  },
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
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    required this.onToggleRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 8, 12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Toggle read/unread
          IconButton(
            icon: Icon(
              isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
              size: 18,
            ),
            color: const Color(0xFF94A3B8),
            tooltip: isRead
                ? AppLocalizations.of(context).markAsUnreadTooltip
                : AppLocalizations.of(context).markAsReadTooltip,
            onPressed: onToggleRead,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: const Color(0xFFE53935),
            tooltip: AppLocalizations.of(context).commonDelete,
            onPressed: onDelete,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
