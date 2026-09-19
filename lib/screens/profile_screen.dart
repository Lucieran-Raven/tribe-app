import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile/profile_reply_card.dart';
import '../widgets/common/skeletons.dart';
import '../design/tribe_design.dart';
import '../utils/affiliation_sort.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
          body: const ProfileSkeleton(),
        ),
      );
    }

    final user = authState.user;
    final userId = user.userId;
    final userRantsAsync = ref.watch(userRantsProvider(userId));
    final userRepliesAsync = ref.watch(userRepliesProvider(userId));
    final userRants = userRantsAsync.value ?? [];
    final userReplies = userRepliesAsync.value ?? [];
    final rantCount = userRants.length;
    final replyCount = userReplies.length;
    final totalKarma = userRants.fold<int>(0, (acc, r) => acc + r.voterIds.length) +
        userReplies.fold<int>(0, (acc, r) => acc + r.voterIds.length);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        appBar: GlassAppBar(
          title: Text('Profile', style: t.display(size: 18, color: t.milk)),
          actions: [
            IconBtn(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: DefaultTabController(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.displayName, style: t.display(size: 16, color: t.milk)),
                                  const SizedBox(height: 2),
                                  Text('@${user.handle ?? 'anonymous'}', style: t.body(size: 13, weight: FontWeight.w700, color: t.ink)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('$rantCount', style: t.display(size: 17, color: t.milk)),
                                            const SizedBox(height: 2),
                                            Text('Posts', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('$replyCount', style: t.display(size: 17, color: t.milk)),
                                            const SizedBox(height: 2),
                                            Text('Replies', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text('$totalKarma', style: t.display(size: 17, color: t.milk)),
                                            const SizedBox(height: 2),
                                            Text('Likes', style: t.caption(size: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user.country != null)
                          Text(user.country!, style: t.body(size: 12, weight: FontWeight.w600, color: t.inkDim)),
                        const SizedBox(height: 6),
                        if (user.bio != null && user.bio!.isNotEmpty)
                          Text(user.bio!, style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
                        const SizedBox(height: 12),
                        if (user.affiliations.isNotEmpty)
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
                        const SizedBox(height: 14),
                        ClayButtonSecondary(
                          label: 'Edit profile',
                          onTap: () => GoRouter.of(context).push('/edit-profile'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedTabBarDelegate(
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        border: Border(bottom: BorderSide(color: t.gold, width: 2)),
                      ),
                      tabs: [
                        Tab(icon: Icon(Icons.grid_view_rounded, color: t.inkFaint)),
                        Tab(icon: Icon(Icons.chat_bubble_outline, color: t.inkFaint)),
                        Tab(icon: Icon(Icons.thumb_up_outlined, color: t.inkFaint)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                userRants.isEmpty
                    ? const Center(child: Text('No posts yet.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(3),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                        itemCount: userRants.length,
                        itemBuilder: (context, index) {
                          final rant = userRants[index];
                          return GestureDetector(
                            onTap: () => GoRouter.of(context).push('/rant/${rant.rantId}'),
                            child: Container(
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
                                          Text('${rant.voterIds.length}', style: t.body(size: 10.5, weight: FontWeight.w700, color: t.inkFaint)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                userReplies.isEmpty
                    ? const Center(child: Text('No replies yet.'))
                    : FutureBuilder<Map<String, String?>>(
                        future: () async {
                          final rantIds = userReplies.map((r) => r.rantId).toSet().toList();
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
                              itemCount: userReplies.length,
                              itemBuilder: (context, index) {
                                final reply = userReplies[index];
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
                            itemCount: userReplies.length,
                            itemBuilder: (context, index) {
                              final reply = userReplies[index];
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
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Failed to load likes'),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(userLikesProvider(userId)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
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
                        return GestureDetector(
                          onTap: () => GoRouter.of(context).push('/rant/${rant.rantId}'),
                          child: Container(
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
                                        Text('${rant.voterIds.length}', style: t.body(size: 10.5, weight: FontWeight.w700, color: t.like)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
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
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) => true;
}


