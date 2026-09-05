import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final bool showX;
  final VoidCallback? onTap;
  const ObsidianChip({super.key, required this.label, this.active = false, this.icon, this.showX = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: active ? const Color(0x24D9AE6E) : ObsidianTokens.bg3,
        border: Border.all(color: active ? const Color(0x59D9AE6E) : ObsidianTokens.line(false)),
        boxShadow: active ? null : ObsidianTokens.clayOutXsDark,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: active ? ObsidianTokens.gold : ObsidianTokens.inkDim), const SizedBox(width: 6)],
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? ObsidianTokens.gold : ObsidianTokens.inkDim)),
        if (showX) ...[const SizedBox(width: 6), Icon(Icons.close, size: 11, color: active ? ObsidianTokens.gold : ObsidianTokens.inkDim)],
      ]),
    ),
  );
}
