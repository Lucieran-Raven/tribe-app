import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/rant_service.dart';
import '../widgets/obsidian/obsidian_snackbar.dart';

class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final blockedUserIds = authState.user.blockedUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Accounts')),
      body: blockedUserIds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No blocked accounts', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text("You haven't blocked anyone yet.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blockedUserIds.length,
              itemBuilder: (context, index) {
                final blockedUserId = blockedUserIds[index];
                return _BlockedUserRow(blockedUserId: blockedUserId);
              },
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
    return userAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ListTile(title: Text('User unavailable')),
      data: (user) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text('@${user.handle ?? 'anonymous'}'),
          subtitle: Text(user.displayName),
          trailing: TextButton(
            onPressed: () async {
              final auth = ref.read(authProvider);
              if (auth is! AuthAuthenticated) return;
              try {
                final freshUser = await RantService().unblockUser(auth.user.userId, blockedUserId);
                ref.read(authProvider.notifier).updateUser(freshUser);
                if (context.mounted) {
                  ObsidianSnackbar.show(context, 'User unblocked');
                }
              } catch (e) {
                if (context.mounted) {
                  ObsidianSnackbar.show(context, 'Failed: $e', error: true);
                }
              }
            },
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}
