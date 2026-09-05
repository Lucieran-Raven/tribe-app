import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/feed_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feed/rant_card.dart';
import '../config/obsidian_tokens.dart';
import '../widgets/obsidian/obsidian_empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      appBar: AppBar(
        backgroundColor: ObsidianTokens.bg0,
        elevation: 0,
        title: Text(
          'Home',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: ObsidianTokens.milk,
          ),
        ),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load feed',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ObsidianTokens.ink,
                ),
              ),
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
            return const ObsidianEmptyState(
              icon: Icons.campaign_outlined,
              headline: 'No posts yet',
              sub: 'Be the first to share.',
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