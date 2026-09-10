import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

final inboxProvider = StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return Stream.value([]);
  }
  final userId = authState.user.userId;
  return NotificationService().streamNotifications(userId);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(inboxProvider);
  final unread = notifications.value?.where((n) => !n.isRead).length ?? 0;
  return unread;
});
