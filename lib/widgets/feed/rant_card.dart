import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/vote_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';
import '../../design/tribe_design.dart';
import 'full_image_viewer.dart';

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
    final t = TribeThemeScope.of(context);

    return NoteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and info
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/user/${widget.rant.userId}'),
            child: Row(
              children: [
                Avatar(
                  handle: widget.rant.handle,
                  imageUrl: widget.rant.avatarUrl,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.rant.handle}',
                        style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink),
                      ),
                      Text(
                        TimeUtils.formatRelativeTime(widget.rant.timestamp),
                        style: t.caption(size: 11),
                      ),
                    ],
                  ),
                ),
                IconBtn(
                  icon: Icons.more_horiz,
                  onTap: () {
                    if (isOwnPost) {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        builder: (ctx) => SizedBox.expand(
                          child: TribeThemeScope(
                            theme: const TribeTheme(true),
                            child: ConfirmModal(
                              title: 'Delete Post?',
                              body: "This can't be undone.",
                              confirmLabel: 'Delete',
                              onClose: () => Navigator.of(ctx).pop(),
                              onConfirm: () async {
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
                                    targetType: 'post',
                                    targetId: widget.rant.rantId,
                                    reporterId: authState.user.userId,
                                    reason: reason,
                                    snippet: widget.rant.content,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Report submitted. Thank you.')),
                                    );
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
          ),
          const SizedBox(height: 12),
          // Content
          GestureDetector(
            onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
            child: Text(
              widget.rant.content,
              style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink),
            ),
          ),
          if (widget.rant.imageUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                  FullImageViewer(imageUrl: widget.rant.imageUrl!))),
              child: ClampedCoverImage(image: NetworkImage(widget.rant.imageUrl!), maxHeight: 220),
            ),
          ],
          const SizedBox(height: 12),
          // Action row
          Row(
            children: [
              ActionPill(
                icon: Icons.chat_bubble_outline,
                label: '${widget.rant.replyCount}',
                onTap: () {
                  GoRouter.of(context).push('/rant/${widget.rant.rantId}');
                },
              ),
              const SizedBox(width: 12),
              ActionPill(
                icon: Icons.thumb_up_outlined,
                label: '${widget.rant.karma}',
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

}
