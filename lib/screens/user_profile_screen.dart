import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_model.dart';
import '../models/affiliation_model.dart';
import '../models/reply_model.dart';
import '../widgets/feed/rant_card.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final rantsAsync = ref.watch(userRantsProvider(userId));
    final repliesAsync = ref.watch(userRepliesProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load profile')),
        data: (user) {
          final rants = rantsAsync.value ?? [];
          final replies = repliesAsync.value ?? [];
          final totalKarma = rants.fold<int>(0, (sum, r) => sum + r.karma) +
              replies.fold<int>(0, (sum, r) => sum + r.karma);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Center(
                child: CircleAvatar(
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
              // Their posts
              Text(
                'Posts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (rants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No posts yet.')),
                )
              else
                ...rants.map((rant) => RantCard(rant: rant)),
            ],
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
