import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reply_model.dart';
import '../../services/rant_service.dart';
import '../../design/tribe_design.dart';
import '../../widgets/common/tap_scale.dart';

class ProfileReplyCard extends StatefulWidget {
  final ReplyModel reply;
  final String? parentSnippet;
  final bool parentDeleted;
  const ProfileReplyCard({
    super.key,
    required this.reply,
    this.parentSnippet,
    this.parentDeleted = false,
  });

  @override
  State<ProfileReplyCard> createState() => _ProfileReplyCardState();
}

class _ProfileReplyCardState extends State<ProfileReplyCard> {
  String? _parentSnippet;
  bool _parentDeleted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadParent();
  }

  Future<void> _loadParent() async {
    if (widget.parentSnippet != null) {
      setState(() {
        _parentSnippet = widget.parentSnippet;
        _parentDeleted = widget.parentDeleted;
        _loading = false;
      });
      return;
    }
    try {
      final rant = await RantService().getRant(widget.reply.rantId);
      if (mounted) {
        setState(() {
          _parentSnippet = rant.content;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parentDeleted = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return TapScale(
      scale: 0.98,
      child: GestureDetector(
        onTap: _parentDeleted ? null : () => GoRouter.of(context).push('/rant/${widget.reply.rantId}'),
        child: Container(
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
              Text('Replied to a post', style: t.caption(size: 11)),
              const SizedBox(height: 8),
              Text(widget.reply.content, style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: t.grey700, width: 2))),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: _loading
                      ? Container(height: 14, width: 200, color: t.grey500)
                      : Text(
                          _parentDeleted ? '[Post not available]' : (_parentSnippet ?? ''),
                          style: t.body(size: 12, weight: FontWeight.w600, color: t.inkFaint),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
          ),
        ),
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


