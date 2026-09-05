import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'compose/compose_screen.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/obsidian/obsidian_bottom_nav.dart';
import '../config/obsidian_tokens.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final inboxAsync = ref.watch(inboxProvider);
    final unreadCount = inboxAsync.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          SearchScreen(),
          InboxScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ObsidianBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            final authState = ref.read(authProvider);
            if (authState is AuthAuthenticated) {
              NotificationService().markAllAsRead(authState.user.userId);
            }
          }
          setState(() => _currentIndex = index);
        },
        onCreateTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: const ComposeScreen(),
            ),
          );
        },
        unreadCount: unreadCount,
      ),
    );
  }
}
