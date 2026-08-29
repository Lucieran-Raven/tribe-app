import 'package:flutter/material.dart';
import '../../models/rant_model.dart';
import '../../utils/time_utils.dart';

class RantCard extends StatelessWidget {
  final RantModel rant;

  const RantCard({super.key, required this.rant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and info
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
            // Content
            Text(
              rant.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            // Action row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon')),
                    );
                  },
                ),
                Text('${rant.replyCount}'),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_upward_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon')),
                    );
                  },
                ),
                Text('${rant.karma}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
