import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../widgets/inbox/notification_card.dart';
import '../config/obsidian_tokens.dart';
import '../widgets/obsidian/obsidian_empty_state.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(inboxProvider);
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: ObsidianTokens.bg0,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      appBar: AppBar(
        backgroundColor: const Color(0x13FFFFFF),
        elevation: 0,
        title: Text(
          'Inbox',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ObsidianTokens.milk,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load notifications: $error',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ObsidianTokens.ink,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(inboxProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const ObsidianEmptyState(
              icon: Icons.inbox_outlined,
              headline: 'No activity yet',
              sub: 'Go post a rant.',
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () {
                  if (notification.targetRantId != null) {
                    GoRouter.of(context).push('/rant/${notification.targetRantId}');
                  }
                  if (!notification.isRead) {
                    NotificationService().markAsRead(
                      authState.user.userId,
                      notification.notificationId,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
