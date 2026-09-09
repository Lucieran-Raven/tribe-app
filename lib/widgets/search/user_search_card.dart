import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../design/tribe_design.dart';

class UserSearchCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const UserSearchCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Avatar(handle: user.handle ?? 'anonymous', imageUrl: user.avatarUrl, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: t.body(size: 14, weight: FontWeight.w700, color: t.ink)),
                  Text('@${user.handle ?? 'anonymous'}', style: t.body(size: 12.5, weight: FontWeight.w600, color: t.inkDim)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: t.inkFaint),
          ],
        ),
      ),
    );
  }
}


