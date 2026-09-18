import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../widgets/inbox/notification_card.dart';
import '../widgets/common/skeletons.dart';
import '../design/tribe_design.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(inboxProvider);
    final authState = ref.watch(authProvider);
    final t = const TribeTheme(true);

    if (authState is! AuthAuthenticated) {
      return TribeThemeScope(
        theme: t,
        child: Scaffold(
          backgroundColor: t.bg1,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        appBar: GlassAppBar(title: Text('Inbox', style: t.display(size: 18, color: t.milk))),
        body: notificationsAsync.when(
          loading: () => ListView.builder(
            itemCount: 4,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const ShimmerBox(width: 40, height: 40, radius: 20),
                    const SizedBox(width: 12),
                    const ShimmerBox(width: 150, height: 12),
                  ]),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 4),
                  const ShimmerBox(width: 200, height: 14),
                ],
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load notifications: $error'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(inboxProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.mail_outline,
                headline: 'No activity yet',
                sub: 'Go post a rant.',
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.notificationId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => TribeThemeScope(
                        theme: const TribeTheme(true),
                        child: ConfirmModal(
                          title: 'Delete notification?',
                          body: 'This will remove the notification from your inbox.',
                          confirmLabel: 'Delete',
                          onClose: () => Navigator.of(ctx).pop(false),
                          onConfirm: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    );
                    return confirmed ?? false;
                  },
                  onDismissed: (direction) async {
                    await NotificationService().deleteNotificationBySource(
                      authState.user.userId,
                      notification.type,
                      notification.fromUserId,
                      notification.targetRantId,
                    );
                    if (context.mounted) Toast.success(context, 'Notification deleted');
                  },
                  child: NotificationCard(
                    notification: notification,
                    onTap: () {
                      GoRouter.of(context).push('/rant/${notification.targetRantId}');
                      if (!notification.isRead) {
                        NotificationService().markAsRead(
                          authState.user.userId,
                          notification.notificationId,
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

