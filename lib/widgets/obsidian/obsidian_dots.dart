import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianDots extends StatelessWidget {
  final int count;
  final int active;
  const ObsidianDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count, (i) {
      final on = i == active;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: on ? 18 : 7, height: 7,
        decoration: BoxDecoration(
          color: on ? ObsidianTokens.gold : ObsidianTokens.bg3,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: on ? Colors.transparent : ObsidianTokens.line(false)),
        ),
      );
    }),
  );
}
