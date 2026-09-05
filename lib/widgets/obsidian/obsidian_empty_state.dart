import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianEmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String? sub;
  const ObsidianEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: ObsidianTokens.bg2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ObsidianTokens.line(false)),
                boxShadow: ObsidianTokens.clayOutSmDark,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: ObsidianTokens.grey500),
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: ObsidianTokens.ink,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ObsidianTokens.inkFaint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
