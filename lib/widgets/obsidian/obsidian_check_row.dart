import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianCheckRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool checked;
  final VoidCallback? onTap;
  const ObsidianCheckRow({super.key, this.leading, required this.title, this.subtitle, this.checked = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ObsidianTokens.line(false)))),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: ObsidianTokens.ink)),
          if (subtitle != null) Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ObsidianTokens.inkFaint)),
        ])),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: checked ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ObsidianTokens.milk, ObsidianTokens.milkDim]) : null,
            color: checked ? null : ObsidianTokens.bg1,
            border: checked ? null : Border.all(color: ObsidianTokens.line(false)),
            boxShadow: checked ? ObsidianTokens.clayOutXsDark : null,
          ),
          alignment: Alignment.center,
          child: checked ? Icon(Icons.check, size: 14, color: ObsidianTokens.bg0) : null,
        ),
      ]),
    ),
  );
}
