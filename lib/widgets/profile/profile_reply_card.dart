import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reply_model.dart';
import '../../services/rant_service.dart';
import '../../utils/time_utils.dart';

class ProfileReplyCard extends StatefulWidget {
  final ReplyModel reply;
  const ProfileReplyCard({super.key, required this.reply});

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _parentDeleted ? null : () => GoRouter.of(context).push('/rant/${widget.reply.rantId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.reply, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Replied to a post',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_loading)
                Container(height: 14, width: 200, color: Colors.grey.shade200)
              else
                Text(
                  _parentDeleted ? '[Post not available]' : (_parentSnippet ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: _parentDeleted ? Colors.red.shade400 : Colors.grey.shade700,
                    fontStyle: _parentDeleted ? FontStyle.italic : FontStyle.normal,
                    decoration: _parentDeleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              const Divider(height: 20),
              Text(
                widget.reply.content,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                TimeUtils.formatRelativeTime(widget.reply.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
