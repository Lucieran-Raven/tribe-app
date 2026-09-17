import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../utils/time_utils.dart';
import '../../design/tribe_design.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  Future<void> _deleteNotification(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) => SizedBox.expand(
        child: TribeThemeScope(
          theme: const TribeTheme(true),
          child: ConfirmModal(
            title: 'Delete notification?',
            body: 'This will remove the notification from your inbox.',
            confirmLabel: 'Delete',
            onClose: () => Navigator.of(ctx).pop(),
            onConfirm: () => Navigator.of(ctx).pop(true),
          ),
        ),
      ),
    );
  if (confirmed != true) return;
  
  final authState = ref.read(authProvider);
  if (authState is AuthAuthenticated) {
    try {
      await NotificationService().deleteNotificationBySource(
        authState.user.userId,
        notification.type,
        notification.fromUserId,
        notification.targetRantId,
      );
      if (context.mounted) {
        Toast.success(context, 'Notification deleted');
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(context, 'Failed to delete: $e');
      }
    }
  }
}

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

    final t = TribeThemeScope.of(context);
    final isLike = notification.type == NotificationType.karma || notification.type == NotificationType.replyKarma;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Avatar(handle: notification.fromHandle, imageUrl: notification.fromAvatarUrl, size: 38),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isLike ? t.likeTint : t.bg3,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.lineStrong),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isLike ? Icons.thumb_up : Icons.chat_bubble,
                      size: 11,
                      color: isLike ? t.like : t.inkDim,
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
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '@${notification.fromHandle} ', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
                        TextSpan(text: actionText, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.inkDim)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (notification.type != NotificationType.karma)
                    Text(
                      notification.targetSnippet,
                      style: t.body(size: 12.5, weight: FontWeight.w600, color: t.inkFaint),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(TimeUtils.formatRelativeTime(notification.timestamp), style: t.caption(size: 11)),
                ],
              ),
            ),
            IconBtn(
              icon: Icons.delete_outline,
              size: 16,
              onTap: () => _deleteNotification(context, ref),
            ),
            const SizedBox(width: 8),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


