import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'compose/compose_screen.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../design/tribe_design.dart';
import '../main.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        NotificationService().syncPlayerId(authState.user.userId);
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('push_prompt_shown') ?? false)) {
          final granted = await OneSignal.Notifications.requestPermission(true);
          if (granted) await OneSignal.User.pushSubscription.optIn();
          await prefs.setBool('push_prompt_shown', true);
        }
      }
      pendingNotificationRoute.addListener(_handlePendingNotification);
      if (pendingNotificationRoute.value != null) _handlePendingNotification();
    });
  }

  void _handlePendingNotification() {
    final route = pendingNotificationRoute.value;
    if (route == null || !mounted) return;
    pendingNotificationRoute.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push(route);
    });
  }

  @override
  void dispose() {
    pendingNotificationRoute.removeListener(_handlePendingNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);
    final unreadCount = ref.watch(unreadCountProvider);
    final currentTab = switch (_currentIndex) {
      0 => TribeTab.home,
      1 => TribeTab.search,
      2 => TribeTab.inbox,
      3 => TribeTab.profile,
      _ => TribeTab.home,
    };

    void markInboxAsRead() {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        NotificationService().markAllAsRead(authState.user.userId);
      }
    }

    void showComposeSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const ComposeScreen(),
        ),
      );
    }

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: const [HomeScreen(), SearchScreen(), InboxScreen(), ProfileScreen()],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          tab: currentTab,
          unreadCount: unreadCount,
          onTab: (tab) {
            if (tab == TribeTab.create) {
              showComposeSheet();
              return;
            }
            if (tab == TribeTab.inbox) markInboxAsRead();
            final newIndex = switch (tab) {
              TribeTab.home => 0,
              TribeTab.search => 1,
              TribeTab.inbox => 2,
              TribeTab.profile => 3,
              _ => 0,
            };
            if (_currentIndex == 1 && newIndex != 1) SearchScreenReset.notify?.call();
            setState(() => _currentIndex = newIndex);
          },
          onCreate: showComposeSheet,
        ),
      ),
    );
  }
}
