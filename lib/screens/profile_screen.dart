import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
    final totalKarma = userRants.fold<int>(0, (sum, r) => sum + r.karma) +
        userReplies.fold<int>(0, (sum, r) => sum + r.karma);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Display Name
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            
            // Handle
            Text(
              '@${user.handle ?? 'anonymous'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Bio
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(
                user.bio!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'Posts', value: '$rantCount'),
                _StatItem(label: 'Replies', value: '$replyCount'),
                _StatItem(label: 'Likes', value: '$totalKarma'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Affiliations
            if (user.affiliations.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Affiliations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
            
            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => GoRouter.of(context).push('/edit-profile'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    GoRouter.of(context).go('/auth');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Delete Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    final rootContext = context; // Capture parent context
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, your posts, and your replies. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close dialog using dialogContext
              setState(() => _isDeleting = true);
              
              try {
                await AuthService().deleteAccount();
                
                // Navigate FIRST using rootContext before resetting state
                if (rootContext.mounted) {
                  GoRouter.of(rootContext).go('/auth');
                }
                
                // Try to sign out, but don't block or crash if it fails
                try {
                  await ref.read(authProvider.notifier).signOut();
                } catch (_) {}
              } catch (e) {
                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e. Please sign in again and retry.')),
                  );
                }
              } finally {
                // Only setState if the screen is still mounted
                if (mounted) {
                  setState(() => _isDeleting = false);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
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
