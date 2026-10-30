import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/rant_service.dart';
import '../widgets/common/skeletons.dart';
import '../design/tribe_design.dart';

class BlockedAccountsScreen extends ConsumerStatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  ConsumerState<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends ConsumerState<BlockedAccountsScreen> {
  final Set<String> _processingBlocks = {};

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    if (authState is! AuthAuthenticated) {
      return TribeThemeScope(
        theme: t,
        child: Scaffold(
          backgroundColor: t.bg1,
          body: const FeedSkeleton(),
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
                  return _BlockedUserRow(
                    blockedUserId: blockedUserId,
                    processingBlocks: _processingBlocks,
                    onProcessingChanged: (userId, isProcessing) {
                      setState(() {
                        if (isProcessing) {
                          _processingBlocks.add(userId);
                        } else {
                          _processingBlocks.remove(userId);
                        }
                      });
                    },
                  );
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
  final Set<String> processingBlocks;
  final Function(String, bool) onProcessingChanged;
  const _BlockedUserRow({
    required this.blockedUserId,
    required this.processingBlocks,
    required this.onProcessingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(blockedUserId));
    final t = TribeThemeScope.of(context);
    final isProcessing = processingBlocks.contains(blockedUserId);

    return userAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            const ShimmerBox(width: 34, height: 34, radius: 17),
            const SizedBox(width: 12),
            const ShimmerBox(width: 120, height: 14),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Text('This account is unavailable', style: t.body(size: 13, color: t.inkDim)),
        ),
      ),
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
              isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CupertinoActivityIndicator(),
                    )
                  : TribeChip(
                      label: 'Unblock',
                      onTap: () async {
                        onProcessingChanged(blockedUserId, true);
                        final auth = ref.read(authProvider);
                        if (auth is! AuthAuthenticated) {
                          onProcessingChanged(blockedUserId, false);
                          return;
                        }
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
                        } finally {
                          onProcessingChanged(blockedUserId, false);
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
