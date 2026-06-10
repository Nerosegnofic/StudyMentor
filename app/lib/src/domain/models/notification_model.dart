enum NotificationType { screenTimeUnlocked, needsWork, systemUpdate, streakAchieved }

class NotificationModel {
  final String id;
  final String parentUid;
  final String? studentUid;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.parentUid,
    this.studentUid,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.isRead,
  });

  NotificationModel copyWith({
    String? id,
    String? parentUid,
    String? studentUid,
    NotificationType? type,
    String? title,
    String? subtitle,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      parentUid: parentUid ?? this.parentUid,
      studentUid: studentUid ?? this.studentUid,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
