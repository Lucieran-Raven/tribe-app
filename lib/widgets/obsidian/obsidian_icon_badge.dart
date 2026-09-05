import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  const ObsidianIconBadge({super.key, required this.icon, this.size = 76});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: ObsidianTokens.bg2,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: ObsidianTokens.line(false)),
      boxShadow: ObsidianTokens.clayOutDark,
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: size * 0.4, color: ObsidianTokens.gold),
  );
}
