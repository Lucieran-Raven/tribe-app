import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../models/rant_model.dart';
import '../../models/reply_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/replies_provider.dart';
import '../../services/rant_service.dart';
import '../../services/notification_service.dart';
import '../../services/search_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/feed/reply_card.dart';
import '../../widgets/feed/full_image_viewer.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/common/mention_autocomplete.dart';
import '../../widgets/common/mention_text.dart';
import '../../design/tribe_design.dart';

class RantDetailScreen extends ConsumerStatefulWidget {
  final String rantId;
  final String? targetReplyId;
  final bool fromNotification;

  const RantDetailScreen({
    super.key,
    required this.rantId,
    this.targetReplyId,
    this.fromNotification = false,
  });

  @override
  ConsumerState<RantDetailScreen> createState() => _RantDetailScreenState();
}

class _RantDetailScreenState extends ConsumerState<RantDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ValueNotifier<List<String>> _mentionedUserIds = ValueNotifier([]);
  final AutoScrollController _scrollController = AutoScrollController();
  bool _isSending = false;
  bool _isPostAvailable = true;
  bool _hasText = false;
  bool _hasScrolled = false;
  late final Future<RantModel> _rantFuture;

  // --- DL-2b FLASH STATE FIELDS ---
  bool _highlightRant = false;
  String? _highlightedReplyId;

  @override
  void initState() {
    super.initState();
    _rantFuture = RantService().getRant(widget.rantId);
    _replyController.addListener(() {
      setState(() {
        _hasText = _replyController.text.trim().isNotEmpty;
      });
    });

    // --- FRAME 1 FADE-IN INIT ---
    _highlightRant = false;
    _highlightedReplyId = null;

    if (widget.fromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (widget.targetReplyId != null && widget.targetReplyId!.isNotEmpty) {
            _highlightedReplyId = widget.targetReplyId;
          } else {
            _highlightRant = true;
          }
        });

        // Clear the flash after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _highlightRant = false;
              _highlightedReplyId = null;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _mentionedUserIds.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSending = true);

    try {
      final user = authState.user;
      final reply = ReplyModel(
        replyId: '',
        rantId: widget.rantId,
        userId: user.userId,
        handle: user.handle ?? 'anonymous',
        avatarUrl: user.avatarUrl,
        content: content,
        timestamp: DateTime.now(),
        mentionedUserIds: _mentionedUserIds.value,
      );

      // Fetch rant to get owner ID for notification and mention deduplication
      final rant = await RantService().getRant(widget.rantId);
      final replyId = await RantService().createReply(reply, postOwnerId: rant.userId);

      if (mounted) {
        _replyController.clear();
        _mentionedUserIds.value = [];
        Toast.success(context, 'Reply sent');
      }

      if (user.userId != rant.userId) {
        debugPrint('=== TRIGGERING NEW REPLY PUSH to ${rant.userId} ===');
        await NotificationService().sendReplyNotification(
          fromUserId: user.userId,
          fromUsername: user.handle ?? 'anonymous',
          fromAvatarUrl: user.avatarUrl ?? '',
          toUserId: rant.userId,
          rantId: widget.rantId,
          replyContent: content,
          replyId: replyId,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Failed to send reply: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  List<Widget> _buildReplyChildren(AsyncValue<List<ReplyModel>> async, TribeTheme t, List<String> blocked) {
    return async.when(
      loading: () => const [],
      error: (error, stack) => const [],
      data: (replies) {
        final visibleReplies = replies.where((r) => !blocked.contains(r.userId)).toList();
        if (visibleReplies.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToTarget(visibleReplies));
          return const [];
        }
        final widgets = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text('${visibleReplies.length} ${visibleReplies.length == 1 ? "reply" : "replies"}', style: t.caption(size: 12)),
          ),
        ];
        for (int i = 0; i < visibleReplies.length; i++) {
          final r = visibleReplies[i];
          widgets.add(AutoScrollTag(
            key: ValueKey(r.replyId),
            controller: _scrollController,
            index: i,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _highlightedReplyId == r.replyId ? t.goldTint : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: _highlightedReplyId == r.replyId
                    ? Border.all(color: t.gold.withValues(alpha: 0.5), width: 2)
                    : null,
              ),
              child: ReplyCard(reply: r),
            ),
          ));
        }
        widgets.add(const SizedBox(height: 8));
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToTarget(visibleReplies));
        return widgets;
      },
    );
  }

  void _tryScrollToTarget(List<ReplyModel> visibleReplies) {
    debugPrint('=== DL-2 SCROLL: _tryScrollToTarget called, _hasScrolled=$_hasScrolled ===');
    if (_hasScrolled) return;
    final targetId = widget.targetReplyId;
    debugPrint('=== DL-2 SCROLL: targetReplyId=$targetId ===');
    if (targetId == null || targetId.isEmpty) {
      debugPrint('=== DL-2 SCROLL: targetReplyId is null or empty, skipping ===');
      return;
    }
    final idx = visibleReplies.indexWhere((r) => r.replyId == targetId);
    debugPrint('=== DL-2 SCROLL: found index=$idx for targetId=$targetId (total replies=${visibleReplies.length}) ===');
    if (idx == -1) {
      debugPrint('=== DL-2 SCROLL: targetId not found in visible replies ===');
      return;
    }
    _hasScrolled = true;
    debugPrint('=== DL-2 SCROLL: executing scrollToIndex to idx=$idx ===');
    _scrollController.scrollToIndex(
      idx,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);

    if (!_isPostAvailable) {
      return TribeThemeScope(
        theme: t,
        child: Scaffold(
          backgroundColor: t.bg1,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: t.inkFaint),
                  const SizedBox(height: 16),
                  Text('Post Unavailable', style: t.display(size: 17, color: t.milk)),
                  const SizedBox(height: 8),
                  Text('This post has been deleted or is no longer available.', textAlign: TextAlign.center, style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
                  const SizedBox(height: 24),
                  ClayButtonSecondary(label: 'Go Back', onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              GlassAppBar(
                leading: IconBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                title: Text('Post', style: t.display(size: 18, color: t.milk)),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _highlightRant ? t.goldTint : t.bg2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _highlightRant ? t.gold.withValues(alpha: 0.5) : t.line,
                          width: _highlightRant ? 2 : 1,
                        ),
                      ),
                      child: FutureBuilder<RantModel>(
                        future: _rantFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 224,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && !snapshot.hasData)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _isPostAvailable) {
                                setState(() => _isPostAvailable = false);
                              }
                            });
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 64, color: t.inkFaint),
                                  const SizedBox(height: 16),
                                  Text('Post Unavailable', style: t.display(size: 18, color: t.ink)),
                                  const SizedBox(height: 8),
                                  Text('This post may have been deleted.', style: t.body(size: 14, color: t.inkDim)),
                                  const SizedBox(height: 24),
                                  ClayButtonSecondary(
                                    label: 'Go Back',
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          }
                          final rant = snapshot.data!;
                          final currentUserId = authState is AuthAuthenticated ? authState.user.userId : null;
                          final isLiked = currentUserId != null && rant.voterIds.contains(currentUserId);
                          final karma = rant.voterIds.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Avatar(handle: rant.handle, imageUrl: rant.avatarUrl, size: 38),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('@${rant.handle}', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
                                        Text(TimeUtils.formatRelativeTime(rant.timestamp), style: t.caption(size: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              MentionText(
                                content: rant.content,
                                style: t.body(size: 16.5, weight: FontWeight.w500, color: t.ink),
                                mentionStyle: t.body(size: 16.5, weight: FontWeight.w600, color: t.gold),
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
                              if (rant.imageUrl != null) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                                      FullImageViewer(imageUrl: rant.imageUrl!))),
                                  child: ClampedCoverImage(image: NetworkImage(rant.imageUrl!), maxHeight: 220),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ActionPill(icon: Icons.chat_bubble_outline, label: '${rant.replyCount}', onTap: null),
                                  const SizedBox(width: 16),
                                  ActionPill(
                                    icon: Icons.thumb_up_outlined,
                                    label: '$karma',
                                    liked: isLiked,
                                    onTap: () async {
                                      if (currentUserId == null) {
                                        Toast.info(context, 'Sign in to like');
                                        return;
                                      }
                                      if (rant.userId == currentUserId) {
                                        Toast.warning(context, "You can't like your own post");
                                        return;
                                      }
                                      try {
                                        await RantService().toggleVote(rant.rantId, currentUserId);
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
                          );
                        },
                      ),
                    ),
                    ..._buildReplyChildren(ref.watch(repliesProvider(widget.rantId)), t, blocked),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: t.glassBgStrong,
                  border: Border(top: BorderSide(color: t.line)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: MentionAutocomplete(
                        controller: _replyController,
                        mentionedUserIds: _mentionedUserIds,
                        child: ClayInput(
                          controller: _replyController,
                          hint: 'Write a reply…',
                          maxLength: 300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TapScale(
                      onTap: _hasText && !_isSending ? _sendReply : null,
                      child: Opacity(
                        opacity: _hasText && !_isSending ? 1.0 : 0.35,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.milk,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: _isSending
                              ? const CupertinoActivityIndicator(radius: 8)
                              : Icon(Icons.send_rounded, size: 18, color: t.bg0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


