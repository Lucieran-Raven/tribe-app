import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feed/rant_card.dart';
import '../widgets/common/skeletons.dart';
import '../design/tribe_design.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF000000),
                  border: Border(bottom: BorderSide(color: Color(0xFF2B2627), width: 1)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      height: 34,
                      child: Image.asset(
                        'assets/branding/tribe_wordmark_header.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: feedAsync.when(
                loading: () => const FeedSkeleton(),
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
                    color: Colors.white,
                    onRefresh: () async {
                      await Future(() async {
                        ref.invalidate(feedProvider);
                        await Future.delayed(const Duration(milliseconds: 500));
                      }).timeout(const Duration(seconds: 5));
                    },
                    child: ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                      itemCount: visibleRants.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
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