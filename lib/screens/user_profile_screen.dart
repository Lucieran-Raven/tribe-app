import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile/profile_reply_card.dart';
import '../services/report_service.dart';
import '../services/rant_service.dart';
import '../design/tribe_design.dart';
import '../utils/affiliation_sort.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) => SizedBox.expand(
        child: TribeThemeScope(
          theme: const TribeTheme(true),
          child: ReportModal(
            onClose: () => Navigator.of(ctx).pop(),
            onSubmit: (String reason) async {
              final authState = ref.read(authProvider);
              if (authState is AuthAuthenticated) {
                await ReportService().reportContent(
                  targetType: 'user',
                  targetId: userId,
                  reporterId: authState.user.userId,
                  reason: reason,
                );
                if (context.mounted) {
                  Toast.success(context, 'Report submitted. Thank you.');
                }
              }
            },
          ),
        ),
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
        Toast.success(context, block ? 'User blocked' : 'User unblocked');
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(context, 'Failed: $e');
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
    final t = const TribeTheme(true);

    if (isBlocked) {
      return TribeThemeScope(
        theme: t,
        child: Scaffold(
          backgroundColor: t.bg1,
          body: SafeArea(
            child: Column(
              children: [
                GlassAppBar(
                  leading: IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/home')),
                  title: userAsync.whenOrNull(data: (u) =>
                      Text('@${u.handle ?? 'anonymous'}', style: t.display(size: 18, color: t.milk)))
                      ?? Text('Profile', style: t.display(size: 18, color: t.milk)),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EmptyState(
                            icon: Icons.block,
                            headline: 'You blocked this user',
                            sub: "You won't see their posts or replies.",
                          ),
                          const SizedBox(height: 8),
                          ClayButtonSecondary(
                            label: 'Unblock',
                            onTap: () => _toggleBlock(context, ref, userId, false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/home')),
                title: userAsync.whenOrNull(data: (u) =>
                    Text('@${u.handle ?? 'anonymous'}', style: t.display(size: 18, color: t.milk)))
                    ?? Text('Profile', style: t.display(size: 18, color: t.milk)),
                actions: [
                  if (authState is AuthAuthenticated && authState.user.userId != userId)
                    IconBtn(icon: Icons.more_horiz, onTap: () => _showMenu(context, ref, isBlocked)),
                ],
              ),
              Expanded(
                child: userAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load profile')),
                  data: (user) {
            final rants = rantsAsync.value ?? [];
            final replies = repliesAsync.value ?? [];
            final totalKarma = rants.fold<int>(0, (acc, r) => acc + r.karma) +
                replies.fold<int>(0, (acc, r) => acc + r.karma);

            return DefaultTabController(
              length: 3,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Avatar(handle: user.handle ?? 'anonymous', imageUrl: user.avatarUrl, size: 78),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('${rants.length}', style: t.display(size: 17, color: t.milk)),
                                            Text('Posts', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('${replies.length}', style: t.display(size: 17, color: t.milk)),
                                            Text('Replies', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('$totalKarma', style: t.display(size: 17, color: t.milk)),
                                            Text('Likes', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(user.displayName, style: t.display(size: 15, color: t.milk)),
                            const SizedBox(height: 1),
                            Text('@${user.handle ?? 'anonymous'}', style: t.body(size: 12.5, weight: FontWeight.w700, color: t.inkDim)),
                            if (user.country != null) ...[
                              const SizedBox(height: 6),
                              Text(user.country!, style: t.body(size: 12, weight: FontWeight.w600, color: t.inkDim)),
                            ],
                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(user.bio!, style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
                            ],
                            if (user.affiliations.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: sortAffiliationsByType(user.affiliations).length,
                                  itemBuilder: (context, index) {
                                    final affiliation = sortAffiliationsByType(user.affiliations)[index];
                                    IconData icon;
                                    if (affiliation.type == 'university') {
                                      icon = Icons.school;
                                    } else if (affiliation.type == 'city') {
                                      icon = Icons.location_city;
                                    } else {
                                      icon = Icons.star;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: TribeChip(icon: icon, label: affiliation.name),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedTabBarDelegate(
                        child: TabBar(
                          labelColor: t.milk,
                          unselectedLabelColor: t.inkFaint,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicatorColor: Colors.transparent,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_view_rounded)),
                            Tab(icon: Icon(Icons.chat_bubble_outline)),
                            Tab(icon: Icon(Icons.thumb_up_outlined)),
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
                        : GridView.builder(
                            padding: const EdgeInsets.all(3),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3,
                            ),
                            itemCount: rants.length,
                            itemBuilder: (context, index) {
                              final rant = rants[index];
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [t.bg3, t.bg1]),
                                  border: Border.all(color: t.line),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.all(11),
                                child: Stack(
                                  children: [
                                    if (rant.imageUrl != null)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Icon(Icons.image_outlined, size: 13, color: t.grey500),
                                      ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rant.content,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.thumb_up, size: 11, color: t.inkFaint),
                                            const SizedBox(width: 5),
                                            Text('${rant.karma}', style: t.body(size: 10.5, weight: FontWeight.w700, color: t.inkFaint)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    replies.isEmpty
                        ? const Center(child: Text('No replies yet.'))
                        : FutureBuilder<Map<String, String?>>(
                            future: () async {
                              final rantIds = replies.map((r) => r.rantId).toSet().toList();
                              final futures = rantIds.map((id) => FirebaseFirestore.instance.collection('rants').doc(id).get());
                              final snapshots = await Future.wait(futures);
                              final Map<String, String?> snippets = {};
                              for (int i = 0; i < rantIds.length; i++) {
                                final doc = snapshots[i];
                                snippets[rantIds[i]] = doc.exists ? (doc.data() as Map<String, dynamic>)['content'] as String? : null;
                              }
                              return snippets;
                            }(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return ListView.builder(
                                  itemCount: replies.length,
                                  itemBuilder: (context, index) {
                                    final reply = replies[index];
                                    return ProfileReplyCard(
                                      reply: reply,
                                      parentSnippet: null,
                                      parentDeleted: false,
                                    );
                                  },
                                );
                              }
                              final snippets = snapshot.data!;
                              return ListView.builder(
                                itemCount: replies.length,
                                itemBuilder: (context, index) {
                                  final reply = replies[index];
                                  final parentDeleted = snippets[reply.rantId] == null;
                                  return ProfileReplyCard(
                                    reply: reply,
                                    parentSnippet: snippets[reply.rantId],
                                    parentDeleted: parentDeleted,
                                  );
                                },
                              );
                            },
                          ),
                    ref.watch(userLikesProvider(userId)).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const Center(child: Text('Failed to load likes')),
                      data: (likedRants) {
                        if (likedRants.isEmpty) return const Center(child: Text('No likes yet.'));
                        return GridView.builder(
                          padding: const EdgeInsets.all(3),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                          itemCount: likedRants.length,
                          itemBuilder: (context, index) {
                            final rant = likedRants[index];
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [t.bg3, t.bg1]),
                                border: Border.all(color: t.line),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(11),
                              child: Stack(
                                children: [
                                  if (rant.imageUrl != null)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.image_outlined, size: 13, color: t.grey500),
                                    ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rant.content,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.thumb_up, size: 11, color: t.like),
                                          const SizedBox(width: 5),
                                          Text('${rant.karma}', style: t.body(size: 10.5, weight: FontWeight.w700, color: t.like)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
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

  void _showMenu(BuildContext context, WidgetRef ref, bool isBlocked) {
    final t = const TribeTheme(true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TribeThemeScope(
        theme: t,
        child: Container(
          decoration: BoxDecoration(
            color: t.bg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: t.lineStrong)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(4))),
              GestureDetector(
                onTap: () { Navigator.of(ctx).pop(); _showReportDialog(context, ref); },
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(children: [
                    Icon(Icons.flag_outlined, size: 17, color: t.ink),
                    const SizedBox(width: 13),
                    Expanded(child: Text('Report User', style: t.body(size: 14, weight: FontWeight.w700, color: t.ink))),
                  ]))),
              Container(height: 1, color: t.line),
              GestureDetector(
                onTap: () { Navigator.of(ctx).pop(); _toggleBlock(context, ref, userId, !isBlocked); },
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(children: [
                    Icon(Icons.block, size: 17, color: t.danger),
                    const SizedBox(width: 13),
                    Expanded(child: Text(isBlocked ? 'Unblock User' : 'Block User',
                      style: t.body(size: 14, weight: FontWeight.w700, color: t.danger))),
                  ]))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;
  const _PinnedTabBarDelegate({required this.child});

  @override
  double get minExtent => child.preferredSize.height;

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = TribeThemeScope.of(context);
    return Container(
      color: t.bg1,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) => false;
}


