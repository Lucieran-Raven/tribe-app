import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/notification_model.dart';
import '../../utils/time_utils.dart';
import '../../config/obsidian_tokens.dart';
import '../obsidian/tribe_avatar.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String actionText;
    IconData typeIcon;
    bool isLikeType;
    switch (notification.type) {
      case NotificationType.reply:
        actionText = 'replied to your post';
        typeIcon = Icons.chat_bubble_outline;
        isLikeType = false;
        break;
      case NotificationType.karma:
        actionText = 'liked your post';
        typeIcon = Icons.thumb_up_off_alt;
        isLikeType = true;
        break;
      case NotificationType.replyKarma:
        actionText = 'liked your reply';
        typeIcon = Icons.thumb_up_off_alt;
        isLikeType = true;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: ObsidianTokens.line(false))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TribeAvatar(
                  handle: notification.fromHandle,
                  avatarUrl: notification.fromAvatarUrl,
                  size: 38,
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLikeType ? const Color(0x2434D399) : ObsidianTokens.bg3,
                      border: Border.all(color: ObsidianTokens.lineStrong(false)),
                      boxShadow: ObsidianTokens.clayOutXsDark,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      typeIcon,
                      size: 11,
                      color: isLikeType ? ObsidianTokens.like : ObsidianTokens.inkDim,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '@${notification.fromHandle} ',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ObsidianTokens.milk,
                          ),
                        ),
                        TextSpan(
                          text: actionText,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: ObsidianTokens.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.targetSnippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ObsidianTokens.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatRelativeTime(notification.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: ObsidianTokens.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ObsidianTokens.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
