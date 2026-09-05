import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    return Text(
      'TRIBE',
      style: GoogleFonts.manrope(
        fontSize: size, fontWeight: FontWeight.w800, color: ObsidianTokens.milk, letterSpacing: -0.02 * size,
      ),
    );
  }
}
