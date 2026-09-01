import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reply_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vote_provider.dart';
import '../../services/rant_service.dart';

class ReplyCard extends ConsumerStatefulWidget {
  final ReplyModel reply;

  const ReplyCard({super.key, required this.reply});

  @override
  ConsumerState<ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends ConsumerState<ReplyCard> {
  bool _isVoting = false;

  @override
  Widget build(BuildContext context) {
    final hasVotedAsync = ref.watch(replyVoteProvider((widget.reply.rantId, widget.reply.replyId)));
    final hasVoted = hasVotedAsync.value ?? false;
    final authState = ref.watch(authProvider);
    final isOwnReply = authState is AuthAuthenticated && authState.user.userId == widget.reply.userId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.reply.avatarUrl != null
                ? NetworkImage(widget.reply.avatarUrl!)
                : null,
            child: widget.reply.avatarUrl == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${widget.reply.handle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TimeUtils.formatRelativeTime(widget.reply.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reply.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _isVoting
                          ? null
                          : () async {
                              if (isOwnReply) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("You can't like your own reply")),
                                );
                                return;
                              }
                              final authState = ref.read(authProvider);
                              if (authState is! AuthAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sign in to like')),
                                );
                                return;
                              }
                              setState(() => _isVoting = true);
                              try {
                                await RantService().toggleReplyVote(widget.reply.rantId, widget.reply.replyId, authState.user.userId);
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
                      child: Icon(
                        hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 16,
                        color: isOwnReply
                            ? Colors.grey
                            : (hasVoted
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.reply.karma}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
