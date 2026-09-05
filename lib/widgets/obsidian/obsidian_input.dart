import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

class ObsidianInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLength;
  final bool showCounter;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final String? errorText;
  final String? successText;
  const ObsidianInput({super.key, this.controller, this.label, this.hint, this.maxLength = 1000, this.showCounter = false, this.onChanged, this.prefix, this.suffix, this.maxLines = 1, this.errorText, this.successText});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null)
        Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(label!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ObsidianTokens.inkDim))),
      Container(
        decoration: BoxDecoration(
          color: ObsidianTokens.bg1,
          borderRadius: BorderRadius.circular(ObsidianTokens.radiusInput),
          border: Border.all(color: errorText != null ? ObsidianTokens.danger : (successText != null ? ObsidianTokens.success : ObsidianTokens.line(false))),
          boxShadow: [
            const BoxShadow(color: Color(0x8C000000), offset: Offset(4, 4), blurRadius: 9, spreadRadius: 0),
            const BoxShadow(color: Color(0x06FFFFFF), offset: Offset(-3, -3), blurRadius: 8),
          ],
        ),
        child: Stack(children: [
          if (prefix != null) Positioned(left: 15, top: 15, child: prefix!),
          TextField(
            controller: controller, onChanged: onChanged, maxLength: maxLength, maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: ObsidianTokens.ink),
            decoration: InputDecoration(
              counterText: '', border: InputBorder.none, hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 14, color: ObsidianTokens.inkFaint),
              contentPadding: EdgeInsets.fromLTRB(prefix != null ? 27 : 15, 14, suffix != null ? 40 : 15, 14),
            ),
          ),
          if (suffix != null) Positioned(right: 14, top: 14, child: suffix!),
        ]),
      ),
      if (showCounter && controller != null)
        Padding(padding: const EdgeInsets.only(top: 4), child: Align(alignment: Alignment.centerRight, child: Text('${controller!.text.length}/$maxLength', style: GoogleFonts.inter(fontSize: 11, color: ObsidianTokens.inkFaint, fontWeight: FontWeight.w600)))),
      if (errorText != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text(errorText!, style: GoogleFonts.inter(fontSize: 12, color: ObsidianTokens.danger, fontWeight: FontWeight.w600))),
      if (successText != null) Padding(padding: const EdgeInsets.only(top: 5), child: Text(successText!, style: GoogleFonts.inter(fontSize: 12, color: ObsidianTokens.success, fontWeight: FontWeight.w600))),
    ]);
  }
}
