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
import '../../services/search_service.dart';
import '../../design/tribe_design.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/common/mention_text.dart';
import 'full_image_viewer.dart';

final Set<String> _processingLikes = {};

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0C0D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2B2627), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and info
          TapScale(
            onTap: () => GoRouter.of(context).push('/user/${widget.rant.userId}'),
            onLongPress: widget.rant.avatarUrl != null && widget.rant.avatarUrl!.isNotEmpty
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullImageViewer(imageUrl: widget.rant.avatarUrl!),
                      ),
                    )
                : null,
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
            child: MentionText(
              content: widget.rant.content,
              style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink),
              mentionStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
              onMentionTap: (handle) async {
                final users = await SearchService().searchUsers(handle);
                final exactMatch = users.where((u) => u.handle?.toLowerCase() == handle.toLowerCase()).toList();
                if (exactMatch.isNotEmpty) {
                  if (context.mounted) GoRouter.of(context).push('/user/${exactMatch.first.userId}');
                } else {
                  if (context.mounted) Toast.error(context, 'This user is not available or has been deleted.');
                }
              },
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
              GestureDetector(
                onTap: () => GoRouter.of(context).push('/rant/${widget.rant.rantId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1819),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2B2627), width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF8F8A8B)),
                    const SizedBox(width: 6),
                    Text('${widget.rant.replyCount}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFFFFFFFF))),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              _V3LikePill(
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
                  if (_processingLikes.contains(widget.rant.rantId)) return;

                  _processingLikes.add(widget.rant.rantId);
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
                    if (context.mounted) Toast.error(context, 'Failed to like: $e');
                  } finally {
                    _processingLikes.remove(widget.rant.rantId);
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

class _V3LikePill extends StatelessWidget {
  final String label;
  final bool liked;
  final VoidCallback onTap;
  const _V3LikePill({required this.label, required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: 0.95,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1819),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: liked ? const Color(0xFFFF3B30) : const Color(0xFF2B2627),
              width: 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 15,
              color: liked ? const Color(0xFFFF3B30) : const Color(0xFF8F8A8B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: liked ? const Color(0xFFFF3B30) : const Color(0xFFFFFFFF),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
