import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';
import '../../design/tribe_design.dart';
import '../../widgets/common/tap_scale.dart';
import 'full_image_viewer.dart';

class RantCard extends ConsumerStatefulWidget {
  final RantModel rant;

  const RantCard({super.key, required this.rant});

  @override
  ConsumerState<RantCard> createState() => _RantCardState();
}

class _RantCardState extends ConsumerState<RantCard> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.user.userId : null;
    final isLiked = currentUserId != null && widget.rant.voterIds.contains(currentUserId);
    final karma = widget.rant.voterIds.length;
    final isOwnPost = authState is AuthAuthenticated && authState.user.userId == widget.rant.userId;
    final t = TribeThemeScope.of(context);

    return NoteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and info
          TapScale(
            onTap: () => GoRouter.of(context).push('/user/${widget.rant.userId}'),
            haptic: true,
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
                        builder: (ctx) {
                          final isDark = Theme.of(ctx).brightness == Brightness.dark;
                          return SizedBox.expand(
                            child: TribeThemeScope(
                              theme: TribeTheme(isDark),
                              child: ConfirmModal(
                              title: 'Delete Post?',
                              body: "This can't be undone.",
                              confirmLabel: 'Delete',
                              onClose: () => Navigator.of(ctx).pop(),
                              onConfirm: () async {
                                Navigator.of(ctx).pop();
                                try {
                                  await RantService().deletePost(widget.rant.rantId);
                                  if (context.mounted) Toast.success(context, 'Post deleted');
                                } catch (e) {
                                  if (context.mounted) {
                                    Toast.error(context, 'Failed to delete: $e');
                                  }
                                }
                              },
                              danger: true,
                            ),
                          ),
                          );
                        },
                      );
                    } else {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        builder: (ctx) {
                          final isDark = Theme.of(ctx).brightness == Brightness.dark;
                          return SizedBox.expand(
                            child: TribeThemeScope(
                              theme: TribeTheme(isDark),
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
                                    Toast.success(context, 'Report submitted. Thank you.');
                                  }
                                }
                              },
                            ),
                          ),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Content
          TapScale(
            onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
            haptic: true,
            scale: 0.98,
            child: Text(
              widget.rant.content,
              style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink),
            ),
          ),
          if (widget.rant.imageUrl != null) ...[
            const SizedBox(height: 12),
            TapScale(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                  FullImageViewer(imageUrl: widget.rant.imageUrl!))),
              haptic: true,
              child: CachedNetworkImage(
                imageUrl: widget.rant.imageUrl!,
                memCacheWidth: 600,
                memCacheHeight: 600,
                placeholder: (context, url) => Container(color: t.bg2),
                errorWidget: (context, url, error) => Icon(Icons.broken_image, color: t.inkFaint),
                imageBuilder: (context, imageProvider) => ClampedCoverImage(
                  image: imageProvider,
                  maxHeight: 220,
                ),
              ),
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
                label: '$karma',
                liked: isLiked,
                onTap: () async {
                  if (currentUserId == null) {
                    Toast.info(context, 'Sign in to like');
                    return;
                  }
                  if (widget.rant.userId == currentUserId) {
                    Toast.warning(context, "You can't like your own post");
                    return;
                  }
                  final optimisticRant = widget.rant.copyWith(
                    voterIds: isLiked
                      ? widget.rant.voterIds.where((id) => id != currentUserId).toList()
                      : [...widget.rant.voterIds, currentUserId],
                  );
                  ref.read(feedProvider.notifier).updateRant(optimisticRant);
                  try {
                    await RantService().toggleVote(widget.rant.rantId, currentUserId);
                  } catch (e) {
                    ref.read(feedProvider.notifier).updateRant(widget.rant);
                    if (context.mounted) {
                      Toast.error(context, 'Failed to like: $e');
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
