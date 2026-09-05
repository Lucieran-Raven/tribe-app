import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';
import 'glass_surface.dart';

class ObsidianSnackbar {
  static void show(BuildContext context, String text, {bool error = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) => Positioned(
      left: 18, right: 18, bottom: 96,
      child: Material(color: Colors.transparent, child: GlassSurface(
        strong: true, borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        child: Row(children: [
          Icon(error ? Icons.error_outline : Icons.check, size: 15, color: error ? ObsidianTokens.danger : ObsidianTokens.success),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ObsidianTokens.milk))),
        ]),
      )),
    ));
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2200), () { if (entry.mounted) entry.remove(); });
  }
}
