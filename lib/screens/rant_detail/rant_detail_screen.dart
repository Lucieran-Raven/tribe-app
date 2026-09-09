import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rant_model.dart';
import '../../models/reply_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/replies_provider.dart';
import '../../services/rant_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/feed/reply_card.dart';
import '../../widgets/feed/full_image_viewer.dart';
import '../../design/tribe_design.dart';

class RantDetailScreen extends ConsumerStatefulWidget {
  final String rantId;

  const RantDetailScreen({super.key, required this.rantId});

  @override
  ConsumerState<RantDetailScreen> createState() => _RantDetailScreenState();
}

class _RantDetailScreenState extends ConsumerState<RantDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;
  bool _isPostAvailable = true;

  @override
  void dispose() {
    _replyController.dispose();
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
      );

      await RantService().createReply(reply);

      if (mounted) {
        _replyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final blocked = authState is AuthAuthenticated ? authState.user.blockedUsers : const <String>[];
    final t = const TribeTheme(true);

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
                  padding: EdgeInsets.zero,
                  children: [
                    FutureBuilder<RantModel>(
                      future: RantService().getRant(widget.rantId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && !snapshot.hasData)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _isPostAvailable) {
                              setState(() => _isPostAvailable = false);
                            }
                          });
                          return const Center(child: CircularProgressIndicator());
                        }
                        final rant = snapshot.data!;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: t.bg2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: t.line),
                          ),
                          child: Column(
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
                              Text(rant.content, style: t.body(size: 16.5, weight: FontWeight.w500, color: t.ink)),
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
                                  ActionPill(icon: Icons.thumb_up_outlined, label: '${rant.karma}', onTap: null),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ref.watch(repliesProvider(widget.rantId)).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Failed to load replies'),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => ref.invalidate(repliesProvider(widget.rantId)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (replies) {
                        final visibleReplies = replies.where((r) => !blocked.contains(r.userId)).toList();
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                              child: Text('${visibleReplies.length} ${visibleReplies.length == 1 ? "reply" : "replies"}', style: t.caption(size: 12)),
                            ),
                            if (visibleReplies.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(34),
                                child: Center(child: Text('Be the first to reply.', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint))),
                              )
                            else
                              ...visibleReplies.map((r) => ReplyCard(reply: r)),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
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
                      child: ClayInput(
                        controller: _replyController,
                        hint: 'Write a reply…',
                        maxLength: 300,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder(
                      valueListenable: _replyController,
                      builder: (context, text, child) {
                        final isEmpty = text.toString().trim().isEmpty;
                        return GestureDetector(
                          onTap: isEmpty || _isSending ? null : _sendReply,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isEmpty ? t.bg2 : null,
                              gradient: isEmpty ? null : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [t.milk, t.milkDim],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: t.line),
                              boxShadow: isEmpty ? null : t.clayMilkOut,
                            ),
                            alignment: Alignment.center,
                            child: _isSending
                                ? const CupertinoActivityIndicator(radius: 8)
                                : Icon(Icons.send, size: 17, color: isEmpty ? t.inkFaint : t.bg0),
                          ),
                        );
                      },
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


