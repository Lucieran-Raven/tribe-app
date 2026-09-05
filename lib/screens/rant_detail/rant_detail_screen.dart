import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rant_model.dart';
import '../../models/reply_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/replies_provider.dart';
import '../../services/rant_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/feed/reply_card.dart';
import '../../config/obsidian_tokens.dart';
import '../../widgets/obsidian/tribe_avatar.dart';
import '../../widgets/obsidian/action_pill.dart';
import '../../widgets/obsidian/obsidian_empty_state.dart';
import '../../widgets/obsidian/obsidian_snackbar.dart';

class RantDetailScreen extends ConsumerStatefulWidget {
  final String rantId;

  const RantDetailScreen({super.key, required this.rantId});

  @override
  ConsumerState<RantDetailScreen> createState() => _RantDetailScreenState();
}

class _RantDetailScreenState extends ConsumerState<RantDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  String _replyText = '';
  bool _isSending = false;
  bool _isPostAvailable = true;

  @override
  void initState() {
    super.initState();
    _replyController.addListener(() {
      setState(() => _replyText = _replyController.text);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final content = _replyText.trim();
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
        setState(() => _replyText = '');
        ObsidianSnackbar.show(context, 'Reply sent');
      }
    } catch (e) {
      if (mounted) {
        ObsidianSnackbar.show(context, 'Failed to send reply: $e', error: true);
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

    if (!_isPostAvailable) {
      return Scaffold(
        backgroundColor: ObsidianTokens.bg0,
        appBar: AppBar(
          backgroundColor: ObsidianTokens.bg0,
          elevation: 0,
          title: Text(
            'Post',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ObsidianTokens.milk,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: ObsidianTokens.grey700),
                const SizedBox(height: 16),
                Text(
                  'Post Unavailable',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ObsidianTokens.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This post has been deleted or is no longer available.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ObsidianTokens.inkFaint,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      appBar: AppBar(
        backgroundColor: ObsidianTokens.bg0,
        elevation: 0,
        title: Text(
          'Post',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: ObsidianTokens.milk,
          ),
        ),
      ),
      body: Column(
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
                margin: const EdgeInsets.all(14),
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
                    Row(
                      children: [
                        TribeAvatar(handle: rant.handle, avatarUrl: rant.avatarUrl, size: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${rant.handle}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ObsidianTokens.ink,
                                ),
                              ),
                              Text(
                                TimeUtils.formatRelativeTime(rant.timestamp),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: ObsidianTokens.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      rant.content,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: ObsidianTokens.ink,
                        height: 1.4,
                      ),
                    ),
                    if (rant.imageUrl != null) ...[
                      const SizedBox(height: 11),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          rant.imageUrl!,
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
                        Icon(Icons.chat_bubble_outline, size: 17, color: ObsidianTokens.inkDim),
                        const SizedBox(width: 5),
                        Text(
                          '${rant.replyCount}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ObsidianTokens.inkDim,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.arrow_upward_outlined, size: 17, color: ObsidianTokens.inkDim),
                        const SizedBox(width: 5),
                        Text(
                          '${rant.karma}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ObsidianTokens.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(color: ObsidianTokens.line(false)),
          Expanded(
            child: ref.watch(repliesProvider(widget.rantId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load replies',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ObsidianTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(repliesProvider(widget.rantId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (replies) {
                final visibleReplies = replies.where((r) => !blocked.contains(r.userId)).toList();
                if (visibleReplies.isEmpty) {
                  return const ObsidianEmptyState(
                    icon: Icons.chat_bubble_outline,
                    headline: 'No replies yet',
                    sub: 'Be the first to reply.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleReplies.length,
                  itemBuilder: (context, index) {
                    return ReplyCard(reply: visibleReplies[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: ObsidianTokens.bg0,
            border: Border(top: BorderSide(color: ObsidianTokens.line(false))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: ObsidianTokens.bg2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: ObsidianTokens.line(false)),
                    boxShadow: ObsidianTokens.clayOutSmDark,
                  ),
                  child: TextField(
                    controller: _replyController,
                    maxLength: 300,
                    onChanged: (value) => setState(() => _replyText = value),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ObsidianTokens.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write a reply…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ObsidianTokens.inkFaint,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _replyText.trim().isEmpty || _isSending
                      ? null
                      : const LinearGradient(
                          colors: [ObsidianTokens.milk, ObsidianTokens.milkDim],
                        ),
                  color: _replyText.trim().isEmpty || _isSending ? ObsidianTokens.bg2 : null,
                  boxShadow: ObsidianTokens.clayOutSmDark,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _replyText.trim().isEmpty || _isSending ? null : _sendReply,
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send,
                              size: 18,
                              color: _replyText.trim().isEmpty || _isSending
                                  ? ObsidianTokens.inkFaint
                                  : ObsidianTokens.bg0,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
