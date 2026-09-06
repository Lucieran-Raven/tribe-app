import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feed/rant_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: feedAsync.when(
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
            return const Center(
              child: Text('No posts yet. Be the first to share.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(feedProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visibleRants.length,
              itemBuilder: (context, index) {
                return RantCard(rant: visibleRants[index]);
              },
            ),
          );
        },
      ),
    );
  }
}