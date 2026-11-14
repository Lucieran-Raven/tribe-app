import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        // Request push permission once per user
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('push_prompt_shown') ?? false)) {
          final granted = await OneSignal.Notifications.requestPermission(true);
          if (granted) {
            await OneSignal.User.pushSubscription.optIn();
          }
          await prefs.setBool('push_prompt_shown', true);
        }
      }

      // Listen for notification taps (Warm/Cold)
      pendingNotificationRoute.addListener(_handlePendingNotification);
      // Handle Cold Start (if value is already set before listener attached)
      if (pendingNotificationRoute.value != null) {
        _handlePendingNotification();
      }
    });
  }

  void _handlePendingNotification() {
    final route = pendingNotificationRoute.value;
    if (route != null && mounted) {
      pendingNotificationRoute.value = null; // Reset signal
      // Switch to Inbox Tab (Index 2)
      if (_currentIndex != 2) {
        setState(() {
          _currentIndex = 2;
        });
      }
    }
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

    // Map _selectedIndex to TribeTab
    // Stack: 0=Home, 1=Search, 2=Inbox, 3=Profile
    // TribeTab: home, search, create, inbox, profile
    TribeTab currentTab;
    switch (_currentIndex) {
      case 0:
        currentTab = TribeTab.home;
        break;
      case 1:
        currentTab = TribeTab.search;
        break;
      case 2:
        currentTab = TribeTab.inbox;
        break;
      case 3:
        currentTab = TribeTab.profile;
        break;
      default:
        currentTab = TribeTab.home;
    }

    // Mark inbox as read when navigating to it
    void markInboxAsRead() {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        NotificationService().markAllAsRead(authState.user.userId);
      }
    }

    // Show compose sheet
    void showComposeSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const ComposeScreen(),
        ),
      );
    }

    return TribeThemeScope(
      theme: t,
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            backgroundColor: t.bg1,
            body: SafeArea(
              child: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeScreen(),
                SearchScreen(),
                InboxScreen(),
                ProfileScreen(),
              ],
            ),
            ),
          bottomNavigationBar: _V3BottomNavBar(
            currentIndex: _currentIndex,
            unreadCount: unreadCount,
            onTab: (newIndex) {
              // Mark inbox as read when navigating to it
              if (newIndex == 2) {
                markInboxAsRead();
              }

              // Reset search when leaving search tab
              if (_currentIndex == 1 && newIndex != 1) {
                SearchScreenReset.notify?.call();
              }

              setState(() => _currentIndex = newIndex);
            },
            onCreate: showComposeSheet,
          ),
        ),
        ),
      ),
    );
  }
}

class _V3BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onCreate;
  final int unreadCount;
  const _V3BottomNavBar({required this.currentIndex, required this.onTab, required this.onCreate, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    Widget navItem(IconData icon, int index, {int badgeCount = 0}) {
      final active = currentIndex == index;
      return GestureDetector(
        onTap: () => onTab(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFFFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 20, color: active ? const Color(0xFF0E0C0D) : const Color(0xFF8F8A8B)),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          border: Border(top: BorderSide(color: Color(0xFF2B2627), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home_rounded, 0),
            navItem(Icons.search_rounded, 1),
            GestureDetector(
              onTap: onCreate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF6D001A),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: const Icon(Icons.add, size: 24, color: Color(0xFFFFFFFF)),
              ),
            ),
            navItem(Icons.mail_outline_rounded, 2, badgeCount: unreadCount),
            navItem(Icons.person_outline_rounded, 3),
          ],
        ),
      ),
    );
  }
}
