import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reply_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vote_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';
import '../../design/tribe_design.dart';

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
    final t = TribeThemeScope.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: t.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _colorForHandle(widget.reply.handle), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(handle: widget.reply.handle, imageUrl: widget.reply.avatarUrl, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('@${widget.reply.handle}', style: t.body(size: 12.5, weight: FontWeight.w800, color: t.ink)),
                        const SizedBox(width: 8),
                        Text(TimeUtils.formatRelativeTime(widget.reply.timestamp), style: t.caption(size: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              IconBtn(
                icon: Icons.more_horiz,
                size: 16,
                onTap: () {
                  if (isOwnReply) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.transparent,
                      builder: (ctx) => SizedBox.expand(
                        child: TribeThemeScope(
                          theme: const TribeTheme(true),
                          child: ConfirmModal(
                            title: 'Delete Reply?',
                            body: "This can't be undone.",
                            confirmLabel: 'Delete',
                            onClose: () => Navigator.of(ctx).pop(),
                            onConfirm: () async {
                              try {
                                await RantService().deleteReply(widget.reply.rantId, widget.reply.replyId);
                              } catch (e) {
                                if (context.mounted) {
                                  Toast.error(context, 'Failed to delete: $e');
                                }
                              }
                            },
                            danger: true,
                          ),
                        ),
                      ),
                    );
                  } else {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.transparent,
                      builder: (ctx) => SizedBox.expand(
                        child: TribeThemeScope(
                          theme: const TribeTheme(true),
                          child: ReportModal(
                            onClose: () => Navigator.of(ctx).pop(),
                            onSubmit: (String reason) async {
                              final authState = ref.read(authProvider);
                              if (authState is AuthAuthenticated) {
                                await ReportService().reportContent(
                                  targetType: 'reply',
                                  targetId: widget.reply.replyId,
                                  reporterId: authState.user.userId,
                                  reason: reason,
                                  snippet: widget.reply.content,
                                );
                                if (context.mounted) {
                                  Toast.success(context, 'Report submitted. Thank you.');
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.reply.content, style: t.body(size: 14, weight: FontWeight.w500, color: t.ink)),
          const SizedBox(height: 8),
          Row(
            children: [
              ActionPill(
                icon: Icons.thumb_up_outlined,
                label: '${widget.reply.karma}',
                liked: hasVoted,
                onTap: _isVoting
                    ? null
                    : () async {
                        if (isOwnReply) {
                          Toast.warning(context, "You can't like your own reply");
                          return;
                        }
                        final authState = ref.read(authProvider);
                        if (authState is! AuthAuthenticated) {
                          Toast.info(context, 'Sign in to like');
                          return;
                        }
                        setState(() => _isVoting = true);
                        try {
                          await RantService().toggleReplyVote(widget.reply.rantId, widget.reply.replyId, authState.user.userId);
                        } catch (e) {
                          if (context.mounted) {
                            Toast.error(context, 'Failed to like: $e');
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

  Color _colorForHandle(String? handle) {
    if (handle == null) return const Color(0xFF6B7280);
    final hash = handle.hashCode;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF43F5E),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
    ];
    return colors[hash.abs() % colors.length];
  }
}


