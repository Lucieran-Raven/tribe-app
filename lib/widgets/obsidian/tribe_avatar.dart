import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';
import 'mascot_avatar.dart';

class TribeAvatar extends StatelessWidget {
  final String handle;
  final String? avatarUrl;
  final double size;
  const TribeAvatar({super.key, required this.handle, this.avatarUrl, this.size = 34});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: MascotAvatar.ringColorFor(handle).withOpacity(0.44), width: 1.5),
          boxShadow: ObsidianTokens.clayOutSmDark,
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => MascotAvatar(handle: handle, size: size),
          ),
        ),
      );
    }
    return MascotAvatar(handle: handle, size: size);
  }
}
