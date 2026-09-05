import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/obsidian_tokens.dart';

enum ObsidianButtonKind { primary, secondary, danger }

class ObsidianButton extends StatefulWidget {
  final String label;
  final ObsidianButtonKind kind;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;
  const ObsidianButton({super.key, required this.label, this.kind = ObsidianButtonKind.primary, this.onPressed, this.loading = false, this.icon});

  @override
  State<ObsidianButton> createState() => _ObsidianButtonState();
}

class _ObsidianButtonState extends State<ObsidianButton> {
  bool pressed = false;
  
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final isPrimary = widget.kind == ObsidianButtonKind.primary;
    final isDanger = widget.kind == ObsidianButtonKind.danger;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ObsidianTokens.radiusButton),
            gradient: isPrimary
                ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ObsidianTokens.milk, ObsidianTokens.milkDim])
                : isDanger
                    ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A231F), Color(0xFF241412)])
                    : null,
            color: (isPrimary || isDanger) ? null : ObsidianTokens.bg3,
            border: (isPrimary || isDanger) ? null : Border.all(color: ObsidianTokens.line(false)),
            boxShadow: !enabled ? [] : (pressed ? [] : (isPrimary ? ObsidianTokens.clayMilkOutDark : ObsidianTokens.clayOutSmDark)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            if (widget.loading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
            else if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
            Text(widget.label, style: GoogleFonts.inter(
              fontSize: 14.5, fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
              color: isPrimary ? ObsidianTokens.bg0 : (isDanger ? ObsidianTokens.danger : ObsidianTokens.ink),
            )),
          ]),
        ),
      ),
    );
  }
}
