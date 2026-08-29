import 'package:flutter/material.dart';
import '../../models/reply_model.dart';
import '../../utils/time_utils.dart';

class ReplyCard extends StatelessWidget {
  final ReplyModel reply;

  const ReplyCard({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: reply.avatarUrl != null
                ? NetworkImage(reply.avatarUrl!)
                : null,
            child: reply.avatarUrl == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${reply.handle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TimeUtils.formatRelativeTime(reply.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
