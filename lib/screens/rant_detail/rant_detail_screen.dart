import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rant_model.dart';
import '../../models/reply_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/replies_provider.dart';
import '../../services/rant_service.dart';
import '../../utils/time_utils.dart';
import '../../widgets/feed/reply_card.dart';

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

    if (!_isPostAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Post Unavailable', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('This post has been deleted or is no longer available.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
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

    // If available, return the normal Scaffold with the FutureBuilder, Divider, Replies, and BottomNavBar
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          // Original rant at top
          FutureBuilder<RantModel>(
            future: RantService().getRant(widget.rantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && !snapshot.hasData)) {
                // Use a post-frame callback to avoid calling setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _isPostAvailable) {
                    setState(() => _isPostAvailable = false);
                  }
                });
                return const Center(child: CircularProgressIndicator()); // Fallback while state updates
              }
              final rant = snapshot.data!;
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: rant.avatarUrl != null
                                ? NetworkImage(rant.avatarUrl!)
                                : null,
                            child: rant.avatarUrl == null
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${rant.handle}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  TimeUtils.formatRelativeTime(rant.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rant.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: null,
                          ),
                          Text('${rant.replyCount}'),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_outlined),
                            onPressed: null,
                          ),
                          Text('${rant.karma}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          // Replies list
          Expanded(
            child: ref.watch(repliesProvider(widget.rantId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
              data: (replies) {
                final visibleReplies = replies.where((r) => !blocked.contains(r.userId)).toList();
                if (visibleReplies.isEmpty) {
                  return const Center(
                    child: Text('Be the first to reply'),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _replyText.trim().isEmpty || _isSending
                    ? null
                    : _sendReply,
                child: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
