import 'package:flutter/material.dart';
import '../../models/user_model.dart';

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
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? const Icon(Icons.person, size: 20)
            : null,
      ),
      title: Text(user.displayName),
      subtitle: Text('@${user.handle ?? 'anonymous'}'),
      onTap: onTap,
    );
  }
}
