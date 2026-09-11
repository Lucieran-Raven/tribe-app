import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reply_model.dart';
import '../../utils/time_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/rant_service.dart';
import '../../services/report_service.dart';
import '../../design/tribe_design.dart';
import '../../widgets/common/tap_scale.dart';

class ReplyCard extends ConsumerWidget {
  final ReplyModel reply;

  const ReplyCard({super.key, required this.reply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.user.userId : null;
    final isLiked = currentUserId != null && reply.voterIds.contains(currentUserId);
    final karma = reply.voterIds.length;
    final isOwnReply = authState is AuthAuthenticated && authState.user.userId == reply.userId;
    final t = TribeThemeScope.of(context);

    return TapScale(
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: t.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: _colorForHandle(reply.handle), width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(handle: reply.handle, imageUrl: reply.avatarUrl, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('@${reply.handle}', style: t.body(size: 12.5, weight: FontWeight.w800, color: t.ink)),
                          const SizedBox(width: 8),
                          Text(TimeUtils.formatRelativeTime(reply.timestamp), style: t.caption(size: 11)),
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
                                  await RantService().deleteReply(reply.rantId, reply.replyId);
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
                                    targetId: reply.replyId,
                                    reporterId: authState.user.userId,
                                    reason: reason,
                                    snippet: reply.content,
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
            Text(reply.content, style: t.body(size: 14, weight: FontWeight.w500, color: t.ink)),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionPill(
                  icon: Icons.thumb_up_outlined,
                  label: '$karma',
                  liked: isLiked,
                  onTap: () async {
                    if (currentUserId == null) {
                      Toast.info(context, 'Sign in to like');
                      return;
                    }
                    if (reply.userId == currentUserId) {
                      Toast.warning(context, "You can't like your own reply");
                      return;
                    }
                    try {
                      await RantService().toggleReplyVote(reply.rantId, reply.replyId, currentUserId);
                    } catch (e) {
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
      ),
    );
  }
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
