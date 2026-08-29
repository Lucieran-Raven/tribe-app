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

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Compute nav highlight index from stack index
    // Stack: 0=Home, 1=Search, 2=Inbox, 3=Profile
    // Nav: 0=Home, 1=Search, 2=Create, 3=Inbox, 4=Profile
    final navIndex = _currentIndex < 2 ? _currentIndex : _currentIndex + 1;

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (index) {
          // Index 2 is Create (+) - shows compose sheet
          if (index == 2) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: const ComposeScreen(),
              ),
            );
            return;
          }

          // Index 3 is Inbox - mark all as read
          if (index == 3) {
            final authState = ref.read(authProvider);
            if (authState is AuthAuthenticated) {
              NotificationService().markAllAsRead(authState.user.userId);
            }
          }
          
          // Map NavigationBar indices to IndexedStack indices
          // Nav: 0=Home, 1=Search, 2=Create(skip), 3=Inbox, 4=Profile
          // Stack: 0=Home, 1=Search, 2=Inbox, 3=Profile
          int stackIndex;
          if (index < 2) {
            stackIndex = index; // Home or Search
          } else {
            stackIndex = index - 1; // Inbox (3->2) or Profile (4->3)
          }
          
          setState(() => _currentIndex = stackIndex);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 32),
            selectedIcon: Icon(Icons.add_circle, size: 32),
            label: '',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0 && navIndex != 3,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0 && navIndex != 3,
              label: Text(unreadCount > 99 ? '99+' : '$unreadCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.inbox),
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
