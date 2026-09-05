import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';

class OrganicBlob extends StatelessWidget {
  final double size;
  final Widget? child;
  const OrganicBlob({super.key, this.size = 84, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(60, 45), topRight: Radius.elliptical(40, 55),
          bottomLeft: Radius.elliptical(45, 40), bottomRight: Radius.elliptical(55, 60),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [ObsidianTokens.milk, ObsidianTokens.milkDim],
        ),
        boxShadow: ObsidianTokens.clayMilkOutDark,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
