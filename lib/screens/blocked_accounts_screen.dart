import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/rant_service.dart';
import '../design/tribe_design.dart';

class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final blockedUserIds = authState.user.blockedUsers;

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                title: Text('Blocked', style: t.display(size: 18, color: t.milk)),
              ),
              Expanded(
                child: blockedUserIds.isEmpty
            ? const EmptyState(
                icon: Icons.block,
                headline: 'No blocked accounts',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: blockedUserIds.length,
                itemBuilder: (context, index) {
                  final blockedUserId = blockedUserIds[index];
                  return _BlockedUserRow(blockedUserId: blockedUserId);
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedUserRow extends ConsumerWidget {
  final String blockedUserId;
  const _BlockedUserRow({required this.blockedUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(blockedUserId));
    final t = TribeThemeScope.of(context);

    return userAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ListTile(title: Text('User unavailable')),
      data: (user) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Avatar(handle: user.handle ?? 'user', imageUrl: user.avatarUrl, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text('@${user.handle ?? 'anonymous'}', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
              ),
              TribeChip(
                label: 'Unblock',
                onTap: () async {
                  final auth = ref.read(authProvider);
                  if (auth is! AuthAuthenticated) return;
                  try {
                    final freshUser = await RantService().unblockUser(auth.user.userId, blockedUserId);
                    ref.read(authProvider.notifier).updateUser(freshUser);
                    if (context.mounted) {
                      Toast.success(context, 'User unblocked');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Toast.error(context, 'Failed: $e');
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
