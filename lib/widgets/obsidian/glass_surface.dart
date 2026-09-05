import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool strong;
  final bool topBorder;
  final bool bottomBorder;
  const GlassSurface({super.key, required this.child, this.padding = EdgeInsets.zero, this.borderRadius, this.strong = false, this.topBorder = false, this.bottomBorder = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (strong ? const Color(0x13FFFFFF) : const Color(0x0BFFFFFF)),
            border: Border(
              top: topBorder ? BorderSide(color: ObsidianTokens.line(false)) : BorderSide.none,
              bottom: bottomBorder ? BorderSide(color: ObsidianTokens.line(false)) : BorderSide.none,
            ),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
