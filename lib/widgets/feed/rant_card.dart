import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/vote_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';
import '../../config/obsidian_tokens.dart';
import '../obsidian/tribe_avatar.dart';
import '../obsidian/action_pill.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ObsidianTokens.bg1,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ObsidianTokens.line(false)),
        boxShadow: ObsidianTokens.clayOutDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/user/${widget.rant.userId}'),
            child: Row(
              children: [
                TribeAvatar(handle: widget.rant.handle, avatarUrl: widget.rant.avatarUrl, size: 38),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.rant.handle}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ObsidianTokens.ink,
                        ),
                      ),
                      Text(
                        TimeUtils.formatRelativeTime(widget.rant.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ObsidianTokens.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: ObsidianTokens.inkDim, size: 20),
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
          const SizedBox(height: 11),
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
            child: Text(
              widget.rant.content,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: ObsidianTokens.ink,
                height: 1.4,
              ),
            ),
          ),
          if (widget.rant.imageUrl != null) ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                widget.rant.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return AspectRatio(
                    aspectRatio: 16/9,
                    child: Container(color: ObsidianTokens.bg2, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              GestureDetector(
                onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 17, color: ObsidianTokens.inkDim),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.rant.replyCount}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ObsidianTokens.inkDim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ActionPill(
                icon: Icons.thumb_up,
                count: widget.rant.karma,
                liked: hasVoted,
                onTap: _isVoting
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
            ],
          ),
        ],
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
