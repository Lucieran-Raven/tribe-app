import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'compose/compose_screen.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../design/tribe_design.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = const TribeTheme(true);

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
        bottomNavigationBar: BottomNavBar(
          tab: currentTab,
          onTab: (tab) {
            // Handle create tab - show compose sheet
            if (tab == TribeTab.create) {
              showComposeSheet();
              return;
            }

            // Mark inbox as read when navigating to it
            if (tab == TribeTab.inbox) {
              markInboxAsRead();
            }

            // Map TribeTab back to _selectedIndex
            int newIndex;
            switch (tab) {
              case TribeTab.home:
                newIndex = 0;
                break;
              case TribeTab.search:
                newIndex = 1;
                break;
              case TribeTab.inbox:
                newIndex = 2;
                break;
              case TribeTab.profile:
                newIndex = 3;
                break;
              default:
                newIndex = 0;
            }

            setState(() => _currentIndex = newIndex);
          },
          onCreate: showComposeSheet,
        ),
      ),
    );
  }
}
