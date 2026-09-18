// ============================================================================
// tribe_design.dart
//
// Design system extraction from tribe_glass.dart (Obsidian Frost)
// for the TRIBE app.
//
// This file contains ONLY the visual design system (theme, colors, widgets).
// No mock data, no screens, no app logic.
// ============================================================================

import 'dart:ui';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/common/tap_scale.dart';

/* ============================================================================
   THEME — "Obsidian Frost" design tokens
   ============================================================================ */

class TribeTheme {
  final bool isDark;
  const TribeTheme(this.isDark);

  // ---- Backgrounds ----
  Color get bg0 => isDark ? const Color(0xFF08080A) : const Color(0xFFF4EFE4);
  Color get bg1 => isDark ? const Color(0xFF121214) : const Color(0xFFF0EADC);
  Color get bg2 => isDark ? const Color(0xFF1A1A1D) : const Color(0xFFF1ECE1);
  Color get bg3 => isDark ? const Color(0xFF222226) : const Color(0xFFE7E0D0);
  Color get bg4 => isDark ? const Color(0xFF2B2B30) : const Color(0xFFDCD2BC);

  // ---- Milk / neutrals ----
  Color get milk => isDark ? const Color(0xFFF3F0E8) : const Color(0xFF1C1A16);
  Color get milkDim => isDark ? const Color(0xFFE4E0D5) : const Color(0xFF322D26);
  Color get white => const Color(0xFFFFFFFF);

  Color get grey100 => isDark ? const Color(0xFFCBC9C5) : const Color(0xFF4A473F);
  Color get grey300 => isDark ? const Color(0xFF9B9995) : const Color(0xFF6E6A5F);
  Color get grey500 => isDark ? const Color(0xFF6E6C6A) : const Color(0xFF837E71);
  Color get grey700 => isDark ? const Color(0xFF47454A) : const Color(0xFFB7AF9C);

  // ---- Ink ----
  Color get ink => isDark ? const Color(0xFFF3F1EC) : const Color(0xFF201D18);
  Color get inkDim => isDark ? const Color(0xFFA9A7A2) : const Color(0xFF5C574C);
  Color get inkFaint => isDark ? const Color(0xFF6F6D6C) : const Color(0xFF837E70);

  // ---- Lines ----
  Color get line => isDark ? const Color(0x12FFFFFF) : const Color(0x38141008);
  Color get lineStrong => isDark ? const Color(0x24FFFFFF) : const Color(0x57141008);

  // ---- Accents ----
  Color get gold => isDark ? const Color(0xFFD9AE6E) : const Color(0xFF9C6B37);
  Color get goldDim => isDark ? const Color(0xFFB9925A) : const Color(0xFF7E5528);
  Color get goldTint => isDark ? const Color(0x24D9AE6E) : const Color(0x249C6B37);

  Color get danger => isDark ? const Color(0xFFE96A5C) : const Color(0xFFB5402F);
  Color get dangerTint => isDark ? const Color(0x29E96A5C) : const Color(0x21B5402F);
  Color get success => isDark ? const Color(0xFF74C79A) : const Color(0xFF1E8256);
  Color get like => isDark ? const Color(0xFF34D399) : const Color(0xFF0E8F63);
  Color get likeTint => isDark ? const Color(0x2434D399) : const Color(0x240E8F63);

  // ---- Glass ----
  Color get glassBg => isDark ? const Color(0x0BFFFFFF) : const Color(0x8CFFFFFF);
  Color get glassBgStrong => isDark ? const Color(0x13FFFFFF) : const Color(0xC7FFFFFF);

  // ---- Clay shadows ----
  List<BoxShadow> get clayOut => isDark
      ? const [
          BoxShadow(color: Color(0x8C000000), offset: Offset(9, 9), blurRadius: 18),
          BoxShadow(color: Color(0x09000000), offset: Offset(-7, -7), blurRadius: 15),
        ]
      : const [
          BoxShadow(color: Color(0x1F141008), offset: Offset(8, 8), blurRadius: 16),
          BoxShadow(color: Color(0xD9FFFFFF), offset: Offset(-6, -6), blurRadius: 13),
        ];

  List<BoxShadow> get clayOutSm => isDark
      ? const [
          BoxShadow(color: Color(0x80000000), offset: Offset(5, 5), blurRadius: 11),
          BoxShadow(color: Color(0x08000000), offset: Offset(-4, -4), blurRadius: 9),
        ]
      : const [
          BoxShadow(color: Color(0x1A141008), offset: Offset(5, 5), blurRadius: 10),
          BoxShadow(color: Color(0xCCFFFFFF), offset: Offset(-4, -4), blurRadius: 9),
        ];

  List<BoxShadow> get clayOutXs => isDark
      ? const [
          BoxShadow(color: Color(0x73000000), offset: Offset(3, 3), blurRadius: 7),
          BoxShadow(color: Color(0x08000000), offset: Offset(-2, -2), blurRadius: 5),
        ]
      : const [
          BoxShadow(color: Color(0x17141008), offset: Offset(3, 3), blurRadius: 7),
          BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-2, -2), blurRadius: 5),
        ];

  List<BoxShadow> get clayMilkOut => isDark
      ? const [
          BoxShadow(color: Color(0x66000000), offset: Offset(8, 8), blurRadius: 18),
          BoxShadow(color: Color(0x66FFFFFF), offset: Offset(-6, -6), blurRadius: 10),
        ]
      : const [
          BoxShadow(color: Color(0x38141008), offset: Offset(8, 8), blurRadius: 18),
          BoxShadow(color: Color(0x80FFFFFF), offset: Offset(-5, -5), blurRadius: 12),
        ];

  // ---- Typography ----
  TextStyle display({double size = 18, Color? color}) => GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * size,
        fontSize: size,
        color: color ?? milk,
      ).copyWith(decoration: TextDecoration.none);

  TextStyle body({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.inter(fontWeight: weight, fontSize: size, color: color ?? ink).copyWith(decoration: TextDecoration.none);

  TextStyle caption({double size = 12, Color? color}) => GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color ?? inkFaint,
      ).copyWith(decoration: TextDecoration.none);
}

class TribeThemeScope extends InheritedWidget {
  final TribeTheme theme;
  const TribeThemeScope({super.key, required this.theme, required super.child});

  static TribeTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TribeThemeScope>()!.theme;

  @override
  bool updateShouldNotify(TribeThemeScope oldWidget) => oldWidget.theme.isDark != theme.isDark;
}

/* ============================================================================
   AVATAR HELPERS
   ============================================================================ */

const kIdentityRingPalette = <Color>[
  Color(0xFF8C8A85),
  Color(0xFF6E6C68),
  Color(0xFFA3A099),
  Color(0xFF5A5854),
  Color(0xFF95928A),
  Color(0xFF78766F),
];

int hashOf(String s) {
  int h = 0;
  for (final code in s.codeUnits) {
    h = code + ((h << 5) - h);
  }
  return h.abs();
}

Color colorForHandle(String handle) => kIdentityRingPalette[hashOf(handle) % kIdentityRingPalette.length];

BorderRadius blobRadius(double w, double h) => BorderRadius.only(
  topLeft: Radius.elliptical(0.60 * w, 0.45 * h),
  topRight: Radius.elliptical(0.40 * w, 0.55 * h),
  bottomRight: Radius.elliptical(0.55 * w, 0.40 * h),
  bottomLeft: Radius.elliptical(0.45 * w, 0.60 * h),
);

/* ============================================================================
   SMALL PIECES
   ============================================================================ */

/// Procedural-mascot placeholder: a lettered clay bubble with a thin identity
/// ring. Swap the child for the real mascot illustration when it's ready —
/// the ring/shadow/sizing here already match the design spec.
class Avatar extends StatelessWidget {
  final String handle;
  final String? imageUrl;
  final File? localFile;
  final double size;
  const Avatar({super.key, required this.handle, this.imageUrl, this.localFile, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final ring = colorForHandle(handle);
    final letter = handle.isNotEmpty ? handle[0].toUpperCase() : '?';

    Widget child;
    if (localFile != null) {
      child = CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(localFile!),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: t.bg3,
          child: Text(letter, style: GoogleFonts.manrope(color: t.ink, fontWeight: FontWeight.w800, fontSize: size * 0.38)),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: size / 2,
          backgroundColor: t.bg3,
          child: Text(letter, style: GoogleFonts.manrope(color: t.ink, fontWeight: FontWeight.w800, fontSize: size * 0.38)),
        ),
      );
    } else {
      child = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [t.bg4, t.bg1]),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: GoogleFonts.manrope(color: t.white, fontWeight: FontWeight.w800, fontSize: size * 0.38),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withValues(alpha: 0.7), width: 1.5),
        boxShadow: t.clayOutSm,
      ),
      child: child,
    );
  }
}

class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Text('TRIBE', style: t.display(size: size, color: t.milk));
  }
}

class TribeStatusBar extends StatelessWidget {
  const TribeStatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: t.body(size: 12, weight: FontWeight.w700, color: t.milk)),
          Row(children: [
            Icon(Icons.signal_cellular_alt, size: 13, color: t.inkDim),
            const SizedBox(width: 5),
            Icon(Icons.wifi, size: 13, color: t.inkDim),
            const SizedBox(width: 5),
            Icon(Icons.battery_full, size: 16, color: t.inkDim),
          ]),
        ],
      ),
    );
  }
}

class GestureBar extends StatelessWidget {
  const GestureBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      alignment: Alignment.center,
      child: Container(
        width: 110,
        height: 4,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class TribeToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;
  
  const TribeToast({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
    this.iconColor = const Color(0xFF4CAF50),
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Stack(children: [
      GestureDetector(
        onTap: onDismiss,
        child: Container(color: Colors.black.withValues(alpha: 0.3)),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 100,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                decoration: BoxDecoration(
                  color: t.glassBgStrong,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.lineStrong),
                  boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 50, offset: Offset(0, 20))],
                ),
                child: Row(children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 11),
                  Expanded(child: Text(message, style: t.body(size: 13, weight: FontWeight.w700, color: t.milk))),
                  const SizedBox(width: 8),
                  IconBtn(icon: Icons.close, size: 16, onTap: onDismiss),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  static void show(BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle,
    Color iconColor = const Color(0xFF4CAF50),
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => TribeThemeScope(
        theme: const TribeTheme(true),
        child: TribeToast(
          message: message,
          icon: icon,
          iconColor: iconColor,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

class Toast {
  static void success(BuildContext context, String msg) =>
    TribeToast.show(context, message: msg, icon: Icons.check_circle, iconColor: const Color(0xFF4CAF50));
  
  static void error(BuildContext context, String msg) =>
    TribeToast.show(context, message: msg, icon: Icons.error, iconColor: const Color(0xFFE53935));
  
  static void warning(BuildContext context, String msg) =>
    TribeToast.show(context, message: msg, icon: Icons.warning, iconColor: const Color(0xFFFFA726));
  
  static void info(BuildContext context, String msg) =>
    TribeToast.show(context, message: msg, icon: Icons.info, iconColor: const Color(0xFF2196F3));
}

/// Primary clay button — milk gradient, scales down + drops shadow on press.
class ClayButtonPrimary extends StatefulWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool loading;
  const ClayButtonPrimary({super.key, required this.label, this.leading, this.onTap, this.loading = false});

  @override
  State<ClayButtonPrimary> createState() => _ClayButtonPrimaryState();
}

class _ClayButtonPrimaryState extends State<ClayButtonPrimary> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final disabled = widget.onTap == null || widget.loading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: widget.loading ? 1.0 : (widget.onTap == null ? 0.35 : 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.milk, t.milkDim]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: widget.loading || widget.onTap == null || _pressed ? const [] : t.clayMilkOut,
            ),
            child: widget.loading
                ? SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: t.bg0))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 8)],
                    Text(widget.label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5, color: t.bg0)),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Secondary clay button — flat bg3 surface. `plain: true` renders it as a
/// borderless text link (used for "Skip for now").
class ClayButtonSecondary extends StatelessWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool plain;
  const ClayButtonSecondary({super.key, required this.label, this.leading, this.onTap, this.textColor, this.plain = false});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return TapScale(
      onTap: onTap,
      haptic: onTap != null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: plain
            ? null
            : BoxDecoration(
                color: t.bg3,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: t.line),
                boxShadow: t.clayOutSm,
              ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5, color: textColor ?? t.ink)),
        ]),
      ),
    );
  }
}

/// "Carved" input: bg1 fill + hairline border (Flutter has no inset
/// BoxShadow, so this simulates the CSS --clay-in look per the design spec).
/// Uses CupertinoTextField with its decoration stripped — no Material
/// TextField chrome anywhere.
class ClayInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final Color? borderColorOverride;
  const ClayInput({
    super.key,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.borderColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColorOverride ?? t.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      child: Row(children: [
        if (prefix != null) ...[prefix!, const SizedBox(width: 6)],
        Expanded(
          child: CupertinoTextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            placeholder: hint,
            placeholderStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: t.inkFaint),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: t.ink),
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        ...suffix != null ? [suffix!] : [],
      ]),
    );
  }
}

class TribeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback? onTap;
  final Widget? trailing;
  const TribeChip({super.key, required this.label, this.icon, this.active = false, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return TapScale(
      onTap: onTap,
      haptic: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? t.goldTint : t.bg3,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? t.gold.withValues(alpha: 0.3) : t.line),
          boxShadow: active ? const [] : t.clayOutXs,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: active ? t.gold : t.inkDim), const SizedBox(width: 5)],
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: active ? t.gold : t.ink)),
          if (trailing != null) ...[const SizedBox(width: 5), trailing!],
        ]),
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool liked;
  final bool bump;
  final VoidCallback? onTap;
  const ActionPill({super.key, required this.icon, required this.label, this.liked = false, this.bump = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return TapScale(
      onTap: onTap,
      haptic: onTap != null,
      scale: 0.92,
      child: AnimatedScale(
        scale: bump ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: liked ? t.likeTint : t.bg3,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: liked ? t.like.withValues(alpha: 0.3) : t.line),
            boxShadow: liked ? const [] : t.clayOutXs,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: liked ? t.like : t.inkDim),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: liked ? t.like : t.ink)),
          ]),
        ),
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  const GlassAppBar({super.key, this.leading, this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(color: t.glassBgStrong, border: Border(bottom: BorderSide(color: t.line))),
          child: Row(children: [
            ...leading != null ? [leading!, const SizedBox(width: 12)] : [],
            if (title != null) Expanded(child: title!),
            ...actions ?? [],
          ]),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(54);
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  const IconBtn({super.key, required this.icon, this.onTap, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: TapScale(
        onTap: onTap,
        haptic: onTap != null,
        child: Center(
          child: Icon(icon, size: size, color: color ?? t.inkDim),
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  const NoteCard({super.key, required this.child, this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 10)});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.05), t.bg2),
            Color.alphaBlend(Colors.white.withValues(alpha: 0.015), t.bg2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
        boxShadow: t.clayOut,
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String? headline;
  final String? sub;
  const EmptyState({super.key, required this.icon, this.headline, this.sub});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 70),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: t.bg2, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.line), boxShadow: t.clayOutSm),
            child: Icon(icon, size: 24, color: t.grey500),
          ),
          const SizedBox(height: 10),
          if (headline != null) Text(headline!, style: t.body(size: 14.5, weight: FontWeight.w700, color: t.ink)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, textAlign: TextAlign.center, style: t.body(size: 12, weight: FontWeight.w600, color: t.inkFaint)),
          ],
        ]),
      ),
    );
  }
}

class MiniCheckbox extends StatelessWidget {
  final bool checked;
  const MiniCheckbox({super.key, required this.checked});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? t.gold : t.bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? t.gold : t.line),
      ),
      child: checked ? Icon(Icons.check, size: 14, color: t.bg0) : null,
    );
  }
}

class MiniRadio extends StatelessWidget {
  final bool checked;
  const MiniRadio({super.key, required this.checked});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: checked ? t.gold : t.line, width: 1.5), color: t.bg3),
      alignment: Alignment.center,
      child: checked ? Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: t.gold)) : null,
    );
  }
}

class MiniToggle extends StatelessWidget {
  final bool on;
  const MiniToggle({super.key, required this.on});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: t.lineStrong),
        gradient: on ? LinearGradient(colors: [t.milk, t.milkDim]) : null,
        color: on ? null : t.bg3,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? t.bg0 : t.inkFaint)),
      ),
    );
  }
}

/* ============================================================================
   BOTTOM NAV
   ============================================================================ */

enum TribeTab { home, search, create, inbox, profile }

class BottomNavBar extends StatelessWidget {
  final TribeTab tab;
  final ValueChanged<TribeTab> onTab;
  final VoidCallback onCreate;
  final int unreadCount;
  const BottomNavBar({
    super.key,
    required this.tab,
    required this.onTab,
    required this.onCreate,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);

    Widget navItem(IconData icon, TribeTab id, {int badgeCount = 0}) {
      final active = tab == id;
      return TapScale(
        onTap: () => onTab(id),
        haptic: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? t.bg3 : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: active ? Border.all(color: t.line) : null,
              ),
              child: Icon(icon, size: 19, color: active ? t.milk : t.grey500),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.bg1, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(color: t.glassBgStrong, border: Border(top: BorderSide(color: t.line))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              navItem(Icons.home_rounded, TribeTab.home),
              navItem(Icons.search_rounded, TribeTab.search),
              TapScale(
                onTap: onCreate,
                haptic: true,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.milk, t.milkDim]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      const BoxShadow(color: Color(0x8CF3F0E8), blurRadius: 28, spreadRadius: 2),
                      const BoxShadow(color: Color(0x66000000), offset: Offset(8, 8), blurRadius: 18),
                      const BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-6, -6), blurRadius: 14),
                    ],
                  ),
                  child: Icon(Icons.add, size: 20, color: t.bg0),
                ),
              ),
              navItem(Icons.mail_outline_rounded, TribeTab.inbox, badgeCount: unreadCount),
              navItem(Icons.person_outline_rounded, TribeTab.profile),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ============================================================================
   MODALS
   ============================================================================ */

class ReportModal extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  const ReportModal({super.key, required this.onClose, required this.onSubmit});
  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _choice;
  bool _isSubmitting = false;
  static const _options = ['Spam', 'Harassment', 'Hate speech', 'Nudity', 'Other'];

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: t.bg2, borderRadius: BorderRadius.circular(28), border: Border.all(color: t.line), boxShadow: t.clayOut),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.flag, size: 17, color: t.danger),
                const SizedBox(width: 8),
                Expanded(child: Text('Report', style: t.display(size: 16, color: t.milk))),
                IconBtn(icon: Icons.close, onTap: widget.onClose),
              ]),
              const SizedBox(height: 6),
              Text('Why are you reporting this?', style: t.body(size: 12, weight: FontWeight.w600, color: t.inkFaint)),
              const SizedBox(height: 6),
              for (final o in _options)
                GestureDetector(
                  onTap: () => setState(() => _choice = o),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [MiniRadio(checked: _choice == o), const SizedBox(width: 10), Text(o, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink))]),
                  ),
                ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: ClayButtonSecondary(label: 'Cancel', onTap: _isSubmitting ? null : widget.onClose)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClayButtonPrimary(
                    label: _isSubmitting ? 'Submitting...' : 'Submit',
                    loading: _isSubmitting,
                    onTap: _choice == null || _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              widget.onSubmit(_choice!);
                              widget.onClose();
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          },
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class ConfirmModal extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  final bool danger;
  const ConfirmModal({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onClose,
    required this.onConfirm,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: t.bg2, borderRadius: BorderRadius.circular(28), border: Border.all(color: t.line), boxShadow: t.clayOut),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.display(size: 16, color: t.milk)),
              const SizedBox(height: 10),
              Text(body, style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: ClayButtonSecondary(label: 'Cancel', onTap: onClose)),
                const SizedBox(width: 10),
                Expanded(
                  child: danger
                      ? GestureDetector(
                          onTap: () {
                            onConfirm();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: t.dangerTint, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.danger.withValues(alpha: 0.35))),
                            child: Text(confirmLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5, color: t.danger)),
                          ),
                        )
                      : ClayButtonPrimary(
                          label: confirmLabel,
                          onTap: () {
                            onConfirm();
                          },
                        ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class ClampedCoverImage extends StatefulWidget {
  final ImageProvider image;
  final double maxHeight;
  const ClampedCoverImage({super.key, required this.image, this.maxHeight = 260});
  @override
  State<ClampedCoverImage> createState() => _ClampedCoverImageState();
}

class _ClampedCoverImageState extends State<ClampedCoverImage> {
  double? _aspect;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ClampedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _removeListener();
      _aspect = null;
      _resolve();
    }
  }

  void _resolve() {
    _stream = widget.image.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (w <= 0 || h <= 0) return;
      final clamped = (w / h).clamp(0.8, 1.78);
      if (mounted) setState(() => _aspect = clamped);
    });
    _stream!.addListener(_listener!);
  }

  void _removeListener() {
    if (_stream != null && _listener != null) _stream!.removeListener(_listener!);
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final ratio = _aspect;
    if (ratio == null) {
      return Container(
        height: 140,
        decoration: BoxDecoration(color: t.bg3, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, size: 24, color: t.grey500),
      );
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final calculatedHeight = width / ratio;
            final constrainedHeight = calculatedHeight.clamp(120.0, widget.maxHeight);
            return SizedBox(
              height: constrainedHeight,
              child: Image(image: widget.image, fit: BoxFit.cover, width: width, height: constrainedHeight),
            );
          },
        ),
      ),
    );
  }
}
