enum NotificationType { reply, karma, replyKarma }

class NotificationModel {
  final String notificationId;
  final NotificationType type;
  final String fromUserId;
  final String fromHandle;
  final String? fromAvatarUrl;
  final String targetRantId;
  final String? targetReplyId;
  final String targetSnippet;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    this.notificationId = '',
    required this.type,
    required this.fromUserId,
    required this.fromHandle,
    this.fromAvatarUrl,
    required this.targetRantId,
    this.targetReplyId,
    required this.targetSnippet,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, {String? notificationId}) {
    return NotificationModel(
      notificationId: notificationId ?? json['notificationId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => NotificationType.reply,
      ),
      fromUserId: json['fromUserId'] as String,
      fromHandle: json['fromHandle'] as String,
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      targetRantId: json['targetRantId'] as String,
      targetReplyId: json['targetReplyId'] as String?,
      targetSnippet: json['targetSnippet'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type.name,
      'fromUserId': fromUserId,
      'fromHandle': fromHandle,
      'fromAvatarUrl': fromAvatarUrl,
      'targetRantId': targetRantId,
      'targetReplyId': targetReplyId,
      'targetSnippet': targetSnippet,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    NotificationType? type,
    String? fromUserId,
    String? fromHandle,
    String? fromAvatarUrl,
    String? targetRantId,
    String? targetReplyId,
    String? targetSnippet,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromHandle: fromHandle ?? this.fromHandle,
      fromAvatarUrl: fromAvatarUrl ?? this.fromAvatarUrl,
      targetRantId: targetRantId ?? this.targetRantId,
      targetReplyId: targetReplyId ?? this.targetReplyId,
      targetSnippet: targetSnippet ?? this.targetSnippet,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
