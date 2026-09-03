import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/vote_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';

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
                    key: ValueKey(widget.rant.avatarUrl),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _confirmDelete(context);
                      } else if (value == 'report') {
                        _showReportDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      if (isOwnPost)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag),
                              SizedBox(width: 8),
                              Text('Report Post'),
                            ],
                          ),
                        ),
                    ],
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
            if (widget.rant.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.rant.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return AspectRatio(
                      aspectRatio: 16/9,
                      child: Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
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
                  onPressed: _isVoting
                      ? null
                      : () async {
                          if (isOwnPost) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("You can't like your own post")),
                            );
                            return;
                          }
                          final authState = ref.read(authProvider);
                          if (authState is! AuthAuthenticated) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please sign in to like')),
                            );
                            return;
                          }
                          setState(() => _isVoting = true);
                          try {
                            await RantService().toggleVote(widget.rant.rantId, authState.user.userId);
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await RantService().deletePost(widget.rant.rantId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Report Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Spam', 'Harassment', 'Hate speech', 'Nudity', 'Other'].map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final authState = ref.read(authProvider);
                        if (authState is AuthAuthenticated) {
                          await ReportService().reportContent(
                            targetType: 'post',
                            targetId: widget.rant.rantId,
                            reporterId: authState.user.userId,
                            reason: selectedReason!,
                            snippet: widget.rant.content,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted. Thank you.')),
                            );
                          }
                        }
                      },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
