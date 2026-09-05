import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class ActionPill extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool liked;
  final VoidCallback? onTap;
  final double iconSize;
  const ActionPill({
    super.key,
    required this.icon,
    required this.count,
    this.liked = false,
    this.onTap,
    this.iconSize = 15,
  });

  @override
  State<ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<ActionPill> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _bump = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
  ]).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bump,
      child: GestureDetector(
        onTap: widget.onTap == null
            ? null
            : () {
                widget.onTap!();
                _ctrl.forward(from: 0);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: widget.liked ? const Color(0x2434D399) : ObsidianTokens.bg3,
            border: Border.all(
              color: widget.liked ? const Color(0x4D34D399) : ObsidianTokens.line(false),
            ),
            boxShadow: ObsidianTokens.clayOutXsDark,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.liked ? ObsidianTokens.like : ObsidianTokens.inkDim,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.liked ? ObsidianTokens.like : ObsidianTokens.inkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
