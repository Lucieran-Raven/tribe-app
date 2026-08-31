import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../utils/time_utils.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String actionText;
    switch (notification.type) {
      case NotificationType.reply:
        actionText = 'replied to your post';
        break;
      case NotificationType.karma:
        actionText = 'liked your post';
        break;
      case NotificationType.replyKarma:
        actionText = 'liked your reply';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: notification.fromAvatarUrl != null
              ? NetworkImage(notification.fromAvatarUrl!)
              : null,
          child: notification.fromAvatarUrl == null
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        title: Text(
          '@${notification.fromHandle} $actionText',
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.targetSnippet,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              TimeUtils.formatRelativeTime(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
