import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feed/rant_card.dart';
import '../design/tribe_design.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];
    final t = const TribeTheme(true);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: GlassAppBar(
                title: const Wordmark(size: 17),
              ),
            ),
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load feed'),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(feedProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (rants) {
                  final visibleRants = rants.where((r) => !blocked.contains(r.userId)).toList();
                  if (visibleRants.isEmpty) {
                    return const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      headline: 'No posts yet',
                      sub: 'Be the first to say something honest.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(feedProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: visibleRants.length,
                      itemBuilder: (context, index) {
                        return RantCard(rant: visibleRants[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}