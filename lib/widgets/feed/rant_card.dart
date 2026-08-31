import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/vote_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';

class RantCard extends ConsumerStatefulWidget {
  final RantModel rant;

  const RantCard({super.key, required this.rant});

  @override
  ConsumerState<RantCard> createState() => _RantCardState();
}

class _RantCardState extends ConsumerState<RantCard> {
  bool _isVoting = false;

  @override
  Widget build(BuildContext context) {
    final voteAsync = ref.watch(userVoteProvider(widget.rant.rantId));
    final hasVoted = voteAsync.value ?? false;
    final authState = ref.watch(authProvider);
    final isOwnPost = authState is AuthAuthenticated && authState.user.userId == widget.rant.userId;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and info
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/user/${widget.rant.userId}'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.rant.avatarUrl != null
                        ? NetworkImage(widget.rant.avatarUrl!)
                        : null,
                    child: widget.rant.avatarUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${widget.rant.handle}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          TimeUtils.formatRelativeTime(widget.rant.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Content
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
              child: Text(
                widget.rant.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            // Action row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    GoRouter.of(context).push('/rant/${widget.rant.rantId}');
                  },
                ),
                Text('${widget.rant.replyCount}'),
                const SizedBox(width: 24),
                IconButton(
                  icon: hasVoted
                      ? const Icon(Icons.thumb_up)
                      : const Icon(Icons.thumb_up_outlined),
                  color: isOwnPost ? Colors.grey : (hasVoted ? Theme.of(context).colorScheme.primary : null),
                  onPressed: isOwnPost || _isVoting
                      ? null
                      : () async {
                          final authState = ref.read(authProvider);
                          if (authState is! AuthAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please sign in to like')),
                            );
                            return;
                          }
                          setState(() => _isVoting = true);
                          try {
                            await RantService().toggleVote(
                                widget.rant.rantId, authState.user.userId);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to like: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isVoting = false);
                            }
                          }
                        },
                ),
                Text('${widget.rant.karma}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
