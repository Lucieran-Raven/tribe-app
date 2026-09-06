import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/affiliation_model.dart';
import '../models/reply_model.dart';
import '../widgets/feed/rant_card.dart';
import '../widgets/profile/profile_reply_card.dart';
import '../services/report_service.dart';
import '../services/rant_service.dart';
import '../utils/time_utils.dart';
import '../config/theme.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Report User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Spam', 'Harassment', 'Hate speech', 'Nudity', 'Other'].map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final authState = ref.read(authProvider);
                        if (authState is AuthAuthenticated) {
                          await ReportService().reportContent(
                            targetType: 'user',
                            targetId: userId,
                            reporterId: authState.user.userId,
                            reason: selectedReason!,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted. Thank you.')),
                            );
                          }
                        }
                      },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleBlock(BuildContext context, WidgetRef ref, String userId, bool block) async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    try {
      final freshUser = block
          ? await RantService().blockUser(auth.user.userId, userId)
          : await RantService().unblockUser(auth.user.userId, userId);
      ref.read(authProvider.notifier).updateUser(freshUser);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(block ? 'User blocked' : 'User unblocked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final rantsAsync = ref.watch(userRantsProvider(userId));
    final repliesAsync = ref.watch(userRepliesProvider(userId));
    final authState = ref.watch(authProvider);
    final isBlocked = authState is AuthAuthenticated && authState.user.blockedUsers.contains(userId);
    final blockedList = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];

    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'unblock') {
                  await _toggleBlock(context, ref, userId, false);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unblock',
                  child: Row(
                    children: [
                      Icon(Icons.lock_open),
                      SizedBox(width: 8),
                      Text('Unblock User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('You blocked this user', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text("You won't see their posts or replies.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _toggleBlock(context, ref, userId, false),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unblock'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (authState is AuthAuthenticated && authState.user.userId != userId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'report') {
                  _showReportDialog(context, ref);
                } else if (value == 'block' || value == 'unblock') {
                  await _toggleBlock(context, ref, userId, value == 'block');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag),
                      SizedBox(width: 8),
                      Text('Report User'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: isBlocked ? 'unblock' : 'block',
                  child: Row(
                    children: [
                      Icon(isBlocked ? Icons.lock_open : Icons.block, color: isBlocked ? null : Colors.red),
                      const SizedBox(width: 8),
                      Text(isBlocked ? 'Unblock User' : 'Block User', style: TextStyle(color: isBlocked ? null : Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load profile')),
        data: (user) {
          final rants = rantsAsync.value ?? [];
          final replies = repliesAsync.value ?? [];
          final totalKarma = rants.fold<int>(0, (sum, r) => sum + r.karma) +
              replies.fold<int>(0, (sum, r) => sum + r.karma);

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          Center(
                            child: CircleAvatar(
                              key: ValueKey(user.avatarUrl),
                              radius: 50,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '@${user.handle ?? 'anonymous'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          if (user.country != null) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                user.country!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (user.bio != null && user.bio!.isNotEmpty)
                            Center(
                              child: Text(
                                user.bio!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(label: 'Posts', value: '${rants.length}'),
                              _StatItem(label: 'Replies', value: '${replies.length}'),
                              _StatItem(label: 'Likes', value: '$totalKarma'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Affiliations
                          if (user.affiliations.isNotEmpty) ...[
                            Text(
                              'Affiliations',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.affiliations.map((affiliation) {
                                IconData icon;
                                if (affiliation.type == 'university') {
                                  icon = Icons.school;
                                } else if (affiliation.type == 'city') {
                                  icon = Icons.location_city;
                                } else {
                                  icon = Icons.star;
                                }
                                return Chip(
                                  avatar: Icon(icon, size: 18),
                                  label: Text(affiliation.name),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedTabBarDelegate(
                      child: TabBar(
                        labelColor: AppTheme.brandPrimary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.brandPrimary,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Replies'),
                          Tab(text: 'Likes'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  rants.isEmpty
                      ? const Center(child: Text('No posts yet.'))
                      : ListView.builder(
                          itemCount: rants.length,
                          itemBuilder: (context, index) => RantCard(rant: rants[index]),
                        ),
                  replies.isEmpty
                      ? const Center(child: Text('No replies yet.'))
                      : ListView.builder(
                          itemCount: replies.length,
                          itemBuilder: (context, index) {
                            final reply = replies[index];
                            return ProfileReplyCard(reply: reply);
                          },
                        ),
                  ref.watch(userLikesProvider(userId)).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Center(child: Text('Failed to load likes')),
                    data: (likedRants) {
                      if (likedRants.isEmpty) return const Center(child: Text('No likes yet.'));
                      return ListView.builder(
                        itemCount: likedRants.length,
                        itemBuilder: (context, index) => RantCard(rant: likedRants[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;
  const _PinnedTabBarDelegate({required this.child});

  @override
  double get minExtent => child.preferredSize.height + 1;

  @override
  double get maxExtent => child.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [child, const Divider(height: 1)],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) => false;
}
