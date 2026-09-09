// ============================================================================
// tribe_glass.dart
//
// Flutter conversion of the "Obsidian Frost" React/JSX design (TribeGlass)
// for the TRIBE app.
//
// USAGE
//   MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: Scaffold(body: SafeArea(child: TribeGlass())),
//   );
//
// DEPENDENCY
//   Add to pubspec.yaml:
//     dependencies:
//       google_fonts: ^6.0.0
//
// ARCHITECTURE NOTES
//   - All data (posts, notifications, affiliations) is local, in-memory state,
//     matching the original JSX mock. Every function that mutates data or
//     talks to "the backend" in the original is marked with
//     `// TODO: CONNECT` — wire these to your real APIs / state layer.
//   - No Material AppBar / Card / TextField / FloatingActionButton is used.
//     Text input uses CupertinoTextField with decoration stripped, wrapped in
//     a custom clay/glass Container, so there is no Material or Cupertino
//     chrome — every surface is a hand-built BoxDecoration.
//   - Theme (dark/light) is exposed through an InheritedWidget
//     (TribeThemeScope), mirroring the CSS custom-property / data-theme
//     pattern used in the JSX.
//   - The procedural SVG "mascot" avatar from the JSX is intentionally
//     replaced (per design-system instructions) with a simple lettered
//     circle + colored identity ring — swap `Avatar` for the real mascot
//     illustration when ready.
//   - Flutter's `BoxDecoration` has no inset/inner shadow, so "carved" /
//     inset surfaces (inputs, active nav pill, toggle track) are simulated
//     with a flat fill color + hairline border, as instructed.
// ============================================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-6, -6), blurRadius: 14),
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
      );

  TextStyle body({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.inter(fontWeight: weight, fontSize: size, color: color ?? ink);

  TextStyle caption({double size = 12, Color? color}) => GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color ?? inkFaint,
      );
}

class TribeThemeScope extends InheritedWidget {
  final TribeTheme theme;
  const TribeThemeScope({super.key, required this.theme, required super.child});

  static TribeTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfType<TribeThemeScope>()!.theme;

  @override
  bool updateShouldNotify(TribeThemeScope oldWidget) => oldWidget.theme.isDark != theme.isDark;
}

/* ============================================================================
   DATA MODELS
   ============================================================================ */

class Reply {
  final int id;
  final String handle;
  final String time;
  final String content;
  int likes;
  bool liked;
  final bool mine;
  Reply({
    required this.id,
    required this.handle,
    required this.time,
    required this.content,
    required this.likes,
    required this.liked,
    required this.mine,
  });
}

class Post {
  final int id;
  final String handle;
  final String time;
  final String content;
  final bool image;
  int likes;
  bool liked;
  final bool mine;
  final List<Reply> replies;
  Post({
    required this.id,
    required this.handle,
    required this.time,
    required this.content,
    required this.image,
    required this.likes,
    required this.liked,
    required this.mine,
    required this.replies,
  });
}

class NotifItem {
  final int id;
  final String type; // 'like' | 'reply'
  final String handle;
  final String text;
  final String snippet;
  final String time;
  final bool unread;
  const NotifItem({
    required this.id,
    required this.type,
    required this.handle,
    required this.text,
    required this.snippet,
    required this.time,
    required this.unread,
  });
}

class Affiliation {
  final String name;
  final String type;
  final IconData icon;
  const Affiliation(this.name, this.type, this.icon);
}

class MeProfile {
  final String handle;
  final String name;
  final String bio;
  final String country;
  final String flag;
  const MeProfile({
    required this.handle,
    required this.name,
    required this.bio,
    required this.country,
    required this.flag,
  });
}

const kMe = MeProfile(
  handle: 'quietrebel22',
  name: 'Anonymous Otter',
  bio: 'Sophomore. Undecided major, decided opinions.',
  country: 'United States',
  flag: '🇺🇸',
);

List<Post> buildInitialPosts() => [
      Post(
        id: 1,
        handle: 'thirdfloorhaunt',
        time: '31m',
        content:
            'Pretty sure the dining hall salad bar peaked during week two of syllabus week. We are now firmly in the rationing era.',
        image: false,
        likes: 212,
        liked: false,
        mine: false,
        replies: [
          Reply(id: 101, handle: 'lowkeyhonest', time: '20m', content: 'The cucumbers have seen things.', likes: 14, liked: false, mine: false),
          Reply(id: 102, handle: 'quietrebel22', time: '12m', content: 'I filed a formal complaint with myself.', likes: 3, liked: false, mine: true),
        ],
      ),
      Post(
        id: 2,
        handle: 'nightowlnora',
        time: '2h',
        content:
            'Started tearing up in the library because someone was chewing ice for forty-five straight minutes. I have never wanted silence more in my life.',
        image: false,
        likes: 498,
        liked: true,
        mine: false,
        replies: [
          Reply(id: 103, handle: 'quietrebel22', time: '1h', content: 'This is a hate crime against my eardrums, solidarity.', likes: 22, liked: false, mine: true),
        ],
      ),
      Post(
        id: 3,
        handle: 'quietrebel22',
        time: '3h',
        content:
            'Unpopular opinion: the group chat that never makes plans but never stops texting is the actual backbone of this campus.',
        image: true,
        likes: 76,
        liked: false,
        mine: true,
        replies: [
          Reply(id: 104, handle: 'campusferal', time: '2h', content: 'Mine has 40k unread and I refuse to leave.', likes: 9, liked: false, mine: false),
        ],
      ),
      Post(
        id: 4,
        handle: 'quietrebel22',
        time: '5h',
        content: "The vending machine on 2 ate my dollar and I've decided to let it live rent free in my head instead.",
        image: false,
        likes: 31,
        liked: false,
        mine: true,
        replies: [],
      ),
    ];

const kNotifs = <NotifItem>[
  NotifItem(id: 1, type: 'like', handle: 'nightowlnora', text: 'liked your post', snippet: 'Pretty sure the dining hall salad bar peaked…', time: '12m', unread: true),
  NotifItem(id: 2, type: 'reply', handle: 'campusferal', text: 'replied to your post', snippet: 'Mine has 40k unread and I refuse to leave', time: '2h', unread: true),
  NotifItem(id: 3, type: 'like', handle: 'lowkeyhonest', text: 'liked your reply', snippet: 'I filed a formal complaint with myself', time: '5h', unread: false),
];

const kAffiliations = <Affiliation>[
  Affiliation('State University', 'University', Icons.school_outlined),
  Affiliation('Austin, TX', 'City', Icons.location_city_outlined),
  Affiliation('Late Night Study Crew', 'Interest', Icons.groups_outlined),
];

const kRecentSearches = <String>['salad bar drama', 'nightowlnora', 'finals week'];

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

/* ============================================================================
   SMALL PIECES
   ============================================================================ */

/// Procedural-mascot placeholder: a lettered clay bubble with a thin identity
/// ring. Swap the child for the real mascot illustration when it's ready —
/// the ring/shadow/sizing here already match the design spec.
class Avatar extends StatelessWidget {
  final String handle;
  final double size;
  const Avatar({super.key, required this.handle, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final ring = colorForHandle(handle);
    final letter = handle.isNotEmpty ? handle[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withOpacity(0.7), width: 1.5),
        boxShadow: t.clayOutSm,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [t.bg4, t.bg1]),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: GoogleFonts.manrope(color: t.white, fontWeight: FontWeight.w800, fontSize: size * 0.38),
        ),
      ),
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class TribeSnackbar extends StatelessWidget {
  final String text;
  const TribeSnackbar({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return ClipRRect(
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check, size: 15, color: t.success),
            const SizedBox(width: 9),
            Flexible(child: Text(text, style: t.body(size: 13, weight: FontWeight.w700, color: t.milk))),
          ]),
        ),
      ),
    );
  }
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
          opacity: disabled && !widget.loading ? 0.5 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.milk, t.milkDim]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _pressed ? const [] : t.clayMilkOut,
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
    return GestureDetector(
      onTap: onTap,
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
            placeholder: hint,
            placeholderStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: t.inkFaint),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: t.ink),
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (suffix != null) suffix!,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? t.goldTint : t.bg3,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? t.gold.withOpacity(0.3) : t.line),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: bump ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: liked ? t.likeTint : t.bg3,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: liked ? t.like.withOpacity(0.3) : t.line),
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

class GlassAppBar extends StatelessWidget {
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
            if (leading != null) leading!,
            if (leading != null) const SizedBox(width: 12),
            if (title != null) Expanded(child: title!),
            if (actions != null) ...actions!,
          ]),
        ),
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: size, color: color ?? t.inkDim)),
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
            Color.alphaBlend(Colors.white.withOpacity(0.05), t.bg2),
            Color.alphaBlend(Colors.white.withOpacity(0.015), t.bg2),
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
  const BottomNavBar({super.key, required this.tab, required this.onTab, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);

    Widget navItem(IconData icon, TribeTab id) {
      final active = tab == id;
      return GestureDetector(
        onTap: () => onTab(id),
        child: Container(
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
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(color: t.glassBgStrong, border: Border(top: BorderSide(color: t.line))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            navItem(Icons.home_rounded, TribeTab.home),
            navItem(Icons.search_rounded, TribeTab.search),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(top: -18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.milk, t.milkDim]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: t.clayMilkOut,
                ),
                child: Icon(Icons.add, size: 20, color: t.bg0),
              ),
            ),
            navItem(Icons.mail_outline_rounded, TribeTab.inbox),
            navItem(Icons.person_outline_rounded, TribeTab.profile),
          ]),
        ),
      ),
    );
  }
}

/* ============================================================================
   SPLASH & AUTH
   ============================================================================ */

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Expanded(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.milk, t.milkDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(30),
              boxShadow: t.clayMilkOut,
            ),
            alignment: Alignment.center,
            child: Text('T', style: t.display(size: 26, color: t.bg0)),
          ),
          const SizedBox(height: 12),
          Wordmark(size: 30),
          const SizedBox(height: 6),
          Text('v1.0.0', style: t.caption(size: 11)),
        ]),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  final bool loading;
  final VoidCallback onSignIn;
  const AuthScreen({super.key, required this.loading, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 54, 26, 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            Column(children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.milk, t.milkDim]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: t.clayMilkOut,
                ),
                alignment: Alignment.center,
                child: Text('T', style: t.display(size: 22, color: t.bg0)),
              ),
              const SizedBox(height: 14),
              Wordmark(size: 30),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(color: t.bg2, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(100), boxShadow: t.clayOutSm),
                child: Text('Where honesty is the algorithm', style: t.body(size: 12.5, weight: FontWeight.w700, color: t.inkDim)),
              ),
            ]),
            Column(children: [
              // TODO: CONNECT — wire to your real Google sign-in flow
              ClayButtonPrimary(
                label: loading ? 'Signing in…' : 'Continue with Google',
                loading: loading,
                leading: loading ? null : Icon(Icons.login, size: 18, color: t.bg0),
                onTap: loading ? null : onSignIn,
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'By continuing you agree to our ', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkFaint)),
                  TextSpan(text: 'Terms', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim).copyWith(decoration: TextDecoration.underline)),
                  TextSpan(text: ' and ', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkFaint)),
                  TextSpan(text: 'Privacy Policy', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim).copyWith(decoration: TextDecoration.underline)),
                ]),
                textAlign: TextAlign.center,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/* ============================================================================
   ONBOARDING
   ============================================================================ */

enum HandleStatus { idle, checking, available, taken, invalid }

class ObData {
  String displayName;
  String handle;
  HandleStatus handleStatus;
  String country;
  List<String> affiliations;
  ObData({
    this.displayName = '',
    this.handle = '',
    this.handleStatus = HandleStatus.idle,
    this.country = '',
    List<String>? affiliations,
  }) : affiliations = affiliations ?? [];
}

class OnboardingScreen extends StatelessWidget {
  final int page;
  final ValueChanged<int> setPage;
  final ObData ob;
  final VoidCallback onJoin;
  const OnboardingScreen({super.key, required this.page, required this.setPage, required this.ob, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final pages = <Widget>[
      ObWelcome(onNext: () => setPage(1)),
      ObAvatarPage(onNext: () => setPage(2), onSkip: () => setPage(2)),
      ObIdentityPage(ob: ob, onNext: () => setPage(3), onChanged: () => setPage(page)),
      ObCountryPage(ob: ob, onNext: () => setPage(4), onChanged: () => setPage(page)),
      ObAffiliationsPage(ob: ob, onJoin: onJoin, onChanged: () => setPage(page)),
    ];
    return Expanded(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Opacity(
              opacity: page == 0 ? 0 : 1,
              child: IconBtn(icon: Icons.arrow_back, onTap: page == 0 ? null : () => setPage(page - 1)),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == page ? t.gold : t.bg3),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ]),
        ),
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(24, 10, 24, 26), child: pages[page])),
      ]),
    );
  }
}

class IconBadge extends StatelessWidget {
  final Widget child;
  final double size;
  const IconBadge({super.key, required this.child, this.size = 76});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.bg2, borderRadius: BorderRadius.circular(24), border: Border.all(color: t.line), boxShadow: t.clayOut),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class ObWelcome extends StatelessWidget {
  final VoidCallback onNext;
  const ObWelcome({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Column(children: [
      Expanded(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconBadge(child: Icon(Icons.groups_rounded, size: 30, color: t.gold)),
            const SizedBox(height: 18),
            Text('Say the\nquiet part.', textAlign: TextAlign.center, style: t.display(size: 22, color: t.milk)),
            const SizedBox(height: 18),
            SizedBox(
              width: 250,
              child: Text(
                "TRIBE is where your campus tells the truth. Post rants and confessions you'd never say under your real name.",
                textAlign: TextAlign.center,
                style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim),
              ),
            ),
          ]),
        ),
      ),
      ClayButtonPrimary(label: 'Get started', onTap: onNext),
    ]);
  }
}

class ObAvatarPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const ObAvatarPage({super.key, required this.onNext, required this.onSkip});
  @override
  State<ObAvatarPage> createState() => _ObAvatarPageState();
}

class _ObAvatarPageState extends State<ObAvatarPage> {
  bool uploaded = false;
  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Column(children: [
      Expanded(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Pick a face', style: t.display(size: 19, color: t.milk)),
            const SizedBox(height: 10),
            Text("It doesn't have to be your face. Just yours.", style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => setState(() => uploaded = true),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.bg2, border: Border.all(color: t.line), boxShadow: t.clayOut),
                  alignment: Alignment.center,
                  child: uploaded ? const Avatar(handle: 'quietrebel22', size: 100) : Icon(Icons.camera_alt_outlined, size: 26, color: t.inkFaint),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [t.milk, t.milkDim]), shape: BoxShape.circle, boxShadow: t.clayMilkOut),
                    alignment: Alignment.center,
                    child: Icon(Icons.camera_alt, size: 13, color: t.bg0),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
      ClayButtonPrimary(label: 'Next', onTap: widget.onNext),
      const SizedBox(height: 10),
      ClayButtonSecondary(label: 'Skip for now', plain: true, textColor: t.inkFaint, onTap: widget.onSkip),
    ]);
  }
}

class ObIdentityPage extends StatefulWidget {
  final ObData ob;
  final VoidCallback onNext;
  final VoidCallback onChanged;
  const ObIdentityPage({super.key, required this.ob, required this.onNext, required this.onChanged});
  @override
  State<ObIdentityPage> createState() => _ObIdentityPageState();
}

class _ObIdentityPageState extends State<ObIdentityPage> {
  Timer? _debounce;
  late TextEditingController _nameCtrl;
  late TextEditingController _handleCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ob.displayName);
    _handleCtrl = TextEditingController(text: widget.ob.handle);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    super.dispose();
  }

  // TODO: CONNECT — replace with a real handle-availability check against your backend
  void _checkHandle(String val) {
    final clean = val.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '');
    widget.ob.handle = clean;
    setState(() => widget.ob.handleStatus = HandleStatus.checking);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        widget.ob.handleStatus =
            clean.length >= 3 ? (clean == 'admin' ? HandleStatus.taken : HandleStatus.available) : HandleStatus.invalid;
      });
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final ob = widget.ob;
    final canNext = ob.displayName.trim().isNotEmpty && ob.handleStatus == HandleStatus.available;
    Color? borderColor;
    if (ob.handleStatus == HandleStatus.available) borderColor = t.success;
    if (ob.handleStatus == HandleStatus.taken || ob.handleStatus == HandleStatus.invalid) borderColor = t.danger;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(Icons.alternate_email, size: 22, color: t.gold),
        const SizedBox(height: 8),
        Text('Choose your identity', style: t.display(size: 18, color: t.milk)),
        const SizedBox(height: 6),
        Text('This is how the tribe will know you.', style: t.body(size: 12.5, weight: FontWeight.w500, color: t.inkDim)),
      ]),
      const SizedBox(height: 18),
      Text('Display name', style: t.caption(size: 11.5, color: t.inkDim)),
      const SizedBox(height: 6),
      ClayInput(
        controller: _nameCtrl,
        hint: 'Anonymous Otter',
        onChanged: (v) {
          ob.displayName = v;
          setState(() {});
          widget.onChanged();
        },
      ),
      const SizedBox(height: 18),
      Text('Handle', style: t.caption(size: 11.5, color: t.inkDim)),
      const SizedBox(height: 6),
      ClayInput(
        controller: _handleCtrl,
        hint: 'quietrebel22',
        prefix: Text('@', style: t.body(size: 14, weight: FontWeight.w700, color: t.inkFaint)),
        borderColorOverride: borderColor,
        onChanged: _checkHandle,
        suffix: ob.handleStatus == HandleStatus.checking
            ? SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: t.inkFaint))
            : ob.handleStatus == HandleStatus.available
                ? Icon(Icons.check, size: 17, color: t.success)
                : (ob.handleStatus == HandleStatus.taken || ob.handleStatus == HandleStatus.invalid)
                    ? Icon(Icons.close, size: 17, color: t.danger)
                    : null,
      ),
      if (ob.handleStatus == HandleStatus.taken)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text("That handle's already claimed.", style: t.body(size: 11.5, weight: FontWeight.w600, color: t.danger))),
      if (ob.handleStatus == HandleStatus.invalid)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text('Use at least 3 letters, numbers, or underscores.', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.danger))),
      if (ob.handleStatus == HandleStatus.available)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text('@${ob.handle} is yours.', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.success))),
      const Spacer(),
      ClayButtonPrimary(label: 'Next', onTap: canNext ? widget.onNext : null),
    ]);
  }
}

class ObCountryPage extends StatelessWidget {
  final ObData ob;
  final VoidCallback onNext;
  final VoidCallback onChanged;
  const ObCountryPage({super.key, required this.ob, required this.onNext, required this.onChanged});

  static const _countries = <List<String>>[
    ['United States', '🇺🇸'],
    ['Canada', '🇨🇦'],
    ['United Kingdom', '🇬🇧'],
    ['Australia', '🇦🇺'],
  ];

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Column(children: [
      Column(children: [
        Icon(Icons.public, size: 22, color: t.gold),
        const SizedBox(height: 8),
        Text("Where's your tribe?", style: t.display(size: 18, color: t.milk)),
      ]),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: t.bg2, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(14), boxShadow: t.clayOutSm),
        child: Text('⚠ You can only set this once. Choose carefully.', style: t.body(size: 12, weight: FontWeight.w700, color: t.inkDim)),
      ),
      const SizedBox(height: 16),
      ClayInput(hint: 'Search countries…'),
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          children: _countries.map((c) {
            final selected = ob.country == c[0];
            return GestureDetector(
              onTap: () {
                ob.country = c[0];
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Text(c[1], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c[0], style: t.body(size: 14, weight: FontWeight.w600, color: t.ink))),
                  MiniCheckbox(checked: selected),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      ClayButtonPrimary(label: 'Next', onTap: ob.country.isNotEmpty ? onNext : null),
    ]);
  }
}

class ObAffiliationsPage extends StatelessWidget {
  final ObData ob;
  final VoidCallback onJoin;
  final VoidCallback onChanged;
  const ObAffiliationsPage({super.key, required this.ob, required this.onJoin, required this.onChanged});

  void _toggle(String name) {
    if (ob.affiliations.contains(name)) {
      ob.affiliations.remove(name);
    } else if (ob.affiliations.length < 5) {
      ob.affiliations.add(name);
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    const filters = ['All', 'Universities', 'Cities', 'Interests'];
    return Column(children: [
      Column(children: [
        Icon(Icons.location_on_outlined, size: 22, color: t.gold),
        const SizedBox(height: 8),
        Text('Find your people', style: t.display(size: 18, color: t.milk)),
      ]),
      const SizedBox(height: 14),
      ClayInput(hint: 'Search schools, cities, interests…'),
      const SizedBox(height: 10),
      SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(
            filters.length,
            (i) => Padding(padding: const EdgeInsets.only(right: 8), child: TribeChip(label: filters[i], active: i == 0)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerLeft, child: Text('${ob.affiliations.length}/5 selected', style: t.caption(size: 11.5))),
      if (ob.affiliations.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ob.affiliations
              .map((a) => TribeChip(label: a, active: true, trailing: Icon(Icons.close, size: 11, color: t.gold), onTap: () => _toggle(a)))
              .toList(),
        ),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: ListView(
          children: kAffiliations.map((a) {
            final selected = ob.affiliations.contains(a.name);
            return GestureDetector(
              onTap: () => _toggle(a.name),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Icon(a.icon, size: 18, color: t.inkDim),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.name, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink)),
                      Text(a.type, style: t.caption(size: 11)),
                    ]),
                  ),
                  MiniCheckbox(checked: selected),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      ClayButtonPrimary(label: 'Join TRIBE', onTap: onJoin),
      const SizedBox(height: 8),
      ClayButtonSecondary(label: 'Skip for now', plain: true, textColor: t.inkFaint, onTap: onJoin),
    ]);
  }
}

/* ============================================================================
   HOME / RANT CARD
   ============================================================================ */

class RantCard extends StatelessWidget {
  final Post post;
  final void Function(int id) onLike;
  final void Function(Post post) onOpen;
  final void Function(Post post) onAvatar;
  final void Function(Post post) onMenu;
  final int? poppedId;
  const RantCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onOpen,
    required this.onAvatar,
    required this.onMenu,
    this.poppedId,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return NoteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => onAvatar(post),
          child: Row(children: [
            Avatar(handle: post.handle),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('@${post.handle}', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
                Text(post.time, style: t.caption(size: 11)),
              ]),
            ),
            IconBtn(icon: Icons.more_horiz, onTap: () => onMenu(post)),
          ]),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => onOpen(post),
          child: Text(post.content, style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink)),
        ),
        if (post.image) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onOpen(post),
            child: Container(
              height: 140,
              decoration: BoxDecoration(color: t.bg3, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
              alignment: Alignment.center,
              child: Icon(Icons.image_outlined, size: 24, color: t.grey500),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          ActionPill(icon: Icons.chat_bubble_outline, label: '${post.replies.length}', onTap: () => onOpen(post)),
          const SizedBox(width: 8),
          ActionPill(
            icon: Icons.thumb_up_outlined,
            label: '${post.likes}',
            liked: post.liked,
            bump: poppedId == post.id,
            onTap: () => onLike(post.id),
          ),
        ]),
      ]),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<Post> posts;
  final void Function(int id) onLike;
  final void Function(Post post) onOpen;
  final void Function(Post post) onAvatar;
  final void Function(Post post) onMenu;
  final int? poppedId;
  const HomeScreen({
    super.key,
    required this.posts,
    required this.onLike,
    required this.onOpen,
    required this.onAvatar,
    required this.onMenu,
    this.poppedId,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        GlassAppBar(title: Wordmark(size: 17)),
        Expanded(
          child: posts.isEmpty
              ? EmptyState(icon: Icons.chat_bubble_outline, headline: 'No posts yet', sub: 'Be the first to say something honest.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: posts.length,
                  itemBuilder: (context, i) =>
                      RantCard(post: posts[i], onLike: onLike, onOpen: onOpen, onAvatar: onAvatar, onMenu: onMenu, poppedId: poppedId),
                ),
        ),
      ]),
    );
  }
}

/* ============================================================================
   POST DETAIL
   ============================================================================ */

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final VoidCallback onBack;
  final void Function(int id) onLikePost;
  final void Function(int postId, int replyId) onLikeReply;
  final void Function(int postId, String text) onSend;
  final void Function(dynamic target, [bool isReply]) onMenu;
  final int? poppedId;
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.onBack,
    required this.onLikePost,
    required this.onLikeReply,
    required this.onSend,
    required this.onMenu,
    this.poppedId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _draftCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _draftCtrl.addListener(_onDraftChanged);
  }

  void _onDraftChanged() => setState(() {});

  // TODO: CONNECT — replace with a real reply-submission API call
  void _handleSend() {
    final text = _draftCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      widget.onSend(widget.post.id, text);
      _draftCtrl.clear();
      if (mounted) setState(() => _sending = false);
    });
  }

  @override
  void dispose() {
    _draftCtrl.removeListener(_onDraftChanged);
    _draftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final post = widget.post;
    final hasText = _draftCtrl.text.trim().isNotEmpty;

    return Expanded(
      child: Column(children: [
        GlassAppBar(
          leading: IconBtn(icon: Icons.arrow_back, onTap: widget.onBack),
          title: Text('Post', style: t.display(size: 18, color: t.milk)),
        ),
        Expanded(
          child: ListView(children: [
            NoteCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Avatar(handle: post.handle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('@${post.handle}', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
                      Text(post.time, style: t.caption(size: 11)),
                    ]),
                  ),
                  IconBtn(icon: Icons.more_horiz, onTap: () => widget.onMenu(post)),
                ]),
                const SizedBox(height: 12),
                Text(post.content, style: t.body(size: 16.5, weight: FontWeight.w500, color: t.ink)),
                if (post.image) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(color: t.bg3, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_outlined, size: 24, color: t.grey500),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  ActionPill(icon: Icons.chat_bubble_outline, label: '${post.replies.length}'),
                  const SizedBox(width: 8),
                  ActionPill(
                    icon: Icons.thumb_up_outlined,
                    label: '${post.likes}',
                    liked: post.liked,
                    bump: widget.poppedId == post.id,
                    onTap: () => widget.onLikePost(post.id),
                  ),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('${post.replies.length} ${post.replies.length == 1 ? 'reply' : 'replies'}', style: t.caption(size: 12)),
            ),
            if (post.replies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(34),
                child: Center(child: Text('Be the first to reply.', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint))),
              ),
            if (post.replies.isNotEmpty)
              ...post.replies.map((r) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: t.bg2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(left: BorderSide(color: colorForHandle(r.handle), width: 2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Avatar(handle: r.handle, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('@${r.handle}', style: t.body(size: 12.5, weight: FontWeight.w800, color: t.ink)),
                            Text(r.time, style: t.caption(size: 11)),
                          ]),
                        ),
                        IconBtn(icon: Icons.more_horiz, size: 16, onTap: () => widget.onMenu(r, true)),
                      ]),
                      const SizedBox(height: 8),
                      Text(r.content, style: t.body(size: 14, weight: FontWeight.w500, color: t.ink)),
                      const SizedBox(height: 8),
                      ActionPill(
                        icon: Icons.thumb_up_outlined,
                        label: '${r.likes}',
                        liked: r.liked,
                        bump: widget.poppedId == r.id,
                        onTap: () => widget.onLikeReply(post.id, r.id),
                      ),
                    ]),
                  )),
            const SizedBox(height: 8),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line)), color: t.glassBgStrong),
          child: Row(children: [
            Expanded(child: ClayInput(controller: _draftCtrl, hint: 'Write a reply…', maxLength: 300)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : _handleSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: hasText ? LinearGradient(colors: [t.milk, t.milkDim]) : null,
                  color: hasText ? null : t.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.line),
                  boxShadow: hasText ? t.clayMilkOut : const [],
                ),
                alignment: Alignment.center,
                child: _sending
                    ? SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: t.ink))
                    : Icon(Icons.send, size: 17, color: hasText ? t.bg0 : t.inkFaint),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/* ============================================================================
   CREATE POST SHEET
   ============================================================================ */

class CreatePostSheet extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(String text, bool hasImage) onPost;
  const CreatePostSheet({super.key, required this.onClose, required this.onPost});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _textCtrl = TextEditingController();
  bool _img = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _textCtrl.removeListener(_onChanged);
    _textCtrl.dispose();
    super.dispose();
  }

  // TODO: CONNECT — replace with a real post-creation API call
  void _submit() {
    setState(() => _posting = true);
    Future.delayed(const Duration(milliseconds: 750), () {
      widget.onPost(_textCtrl.text, _img);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(color: t.bg1, borderRadius: const BorderRadius.vertical(top: Radius.circular(34)), border: Border.all(color: t.line)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(4))),
                  Row(children: [
                    Expanded(child: Text('Create post', style: t.display(size: 17, color: t.milk))),
                    IconBtn(icon: Icons.close, onTap: widget.onClose),
                  ]),
                  const SizedBox(height: 14),
                  ClayInput(controller: _textCtrl, hint: "What's on your mind?", maxLines: 4, maxLength: 500),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(padding: const EdgeInsets.only(top: 4, bottom: 12), child: Text('${_textCtrl.text.length}/500', style: t.caption(size: 11))),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TribeChip(icon: Icons.image_outlined, label: _img ? 'Photo attached' : 'Add photo', onTap: () => setState(() => _img = !_img)),
                  ),
                  if (_img) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: t.bg3, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined, size: 22, color: t.grey500),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ClayButtonSecondary(label: 'Cancel', onTap: widget.onClose)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClayButtonPrimary(
                        label: 'Post',
                        loading: _posting,
                        onTap: (_textCtrl.text.trim().isEmpty || _posting) ? null : _submit,
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================================
   SEARCH
   ============================================================================ */

class SearchScreen extends StatefulWidget {
  final List<Post> posts;
  const SearchScreen({super.key, required this.posts});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _qCtrl = TextEditingController();
  List<String> _recents = List.of(kRecentSearches);

  @override
  void initState() {
    super.initState();
    _qCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _qCtrl.removeListener(_onChanged);
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final q = _qCtrl.text;
    final results = q.isEmpty
        ? <Post>[]
        : widget.posts.where((p) => p.content.toLowerCase().contains(q.toLowerCase()) || p.handle.contains(q.toLowerCase())).toList();

    return Expanded(
      child: Column(children: [
        GlassAppBar(title: Text('Search', style: t.display(size: 18, color: t.milk))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: ClayInput(controller: _qCtrl, hint: 'Search posts or users…', prefix: Icon(Icons.search, size: 16, color: t.inkFaint)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              if (q.isEmpty) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recent', style: t.caption(size: 12)),
                  GestureDetector(onTap: () => setState(() => _recents = []), child: Text('Clear all', style: t.body(size: 12, weight: FontWeight.w700, color: t.gold))),
                ]),
                if (_recents.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('No recent searches.', style: t.body(size: 12.5, weight: FontWeight.w600, color: t.inkFaint))),
                for (final r in _recents)
                  GestureDetector(
                    onTap: () => setState(() => _qCtrl.text = r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Icon(Icons.search, size: 14, color: t.inkFaint),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink))),
                        GestureDetector(onTap: () => setState(() => _recents.remove(r)), child: Icon(Icons.close, size: 14, color: t.inkFaint)),
                      ]),
                    ),
                  ),
              ],
              if (q.isNotEmpty && results.isEmpty)
                Padding(padding: const EdgeInsets.all(44), child: Center(child: Text('No results for "$q"', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint)))),
              if (q.isNotEmpty && results.isNotEmpty) ...[
                Text('Posts', style: t.caption(size: 12)),
                const SizedBox(height: 8),
                for (final p in results)
                  NoteCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Avatar(handle: p.handle, size: 30), const SizedBox(width: 8), Text('@${p.handle}', style: t.body(size: 12.5, weight: FontWeight.w800, color: t.ink))]),
                      const SizedBox(height: 8),
                      Text(p.content, style: t.body(size: 14, weight: FontWeight.w500, color: t.ink)),
                    ]),
                  ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

/* ============================================================================
   INBOX
   ============================================================================ */

class InboxScreen extends StatelessWidget {
  final List<NotifItem> notifs;
  const InboxScreen({super.key, required this.notifs});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Expanded(
      child: Column(children: [
        GlassAppBar(title: Text('Inbox', style: t.display(size: 18, color: t.milk))),
        Expanded(
          child: notifs.isEmpty
              ? EmptyState(icon: Icons.mail_outline, headline: 'No activity yet', sub: 'Go post a rant.')
              : ListView(
                  children: notifs.map((n) {
                    final icon = n.type == 'like' ? Icons.thumb_up : Icons.chat_bubble;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Avatar(handle: n.handle, size: 38),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(color: n.type == 'like' ? t.likeTint : t.bg3, shape: BoxShape.circle, border: Border.all(color: t.lineStrong)),
                              alignment: Alignment.center,
                              child: Icon(icon, size: 11, color: n.type == 'like' ? t.like : t.inkDim),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(text: '@${n.handle} ', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink)),
                                TextSpan(text: n.text, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.inkDim)),
                              ]),
                            ),
                            const SizedBox(height: 2),
                            Text(n.snippet, style: t.body(size: 12.5, weight: FontWeight.w600, color: t.inkFaint)),
                            const SizedBox(height: 4),
                            Text(n.time, style: t.caption(size: 11)),
                          ]),
                        ),
                        if (n.unread) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: t.gold)),
                      ]),
                    );
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

/* ============================================================================
   PROFILE (IG-inspired arrangement)
   ============================================================================ */

class IgTile extends StatelessWidget {
  final Post post;
  final VoidCallback onOpen;
  const IgTile({super.key, required this.post, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [t.bg3, t.bg1], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(11),
        child: Stack(children: [
          if (post.image) Positioned(top: 0, right: 0, child: Icon(Icons.image_outlined, size: 13, color: t.grey500)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(post.content, maxLines: 4, overflow: TextOverflow.ellipsis, style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim))),
            Row(children: [
              Icon(Icons.thumb_up, size: 11, color: post.liked ? t.like : t.inkFaint),
              const SizedBox(width: 5),
              Text('${post.likes}', style: t.body(size: 10.5, weight: FontWeight.w700, color: post.liked ? t.like : t.inkFaint)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final List<Post> posts;
  final String tab; // 'posts' | 'replies' | 'likes'
  final ValueChanged<String> setTab;
  final void Function(Post? post, [bool back]) onOpen;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final String? otherHandle;
  const ProfileScreen({
    super.key,
    required this.posts,
    required this.tab,
    required this.setTab,
    required this.onOpen,
    required this.onEdit,
    required this.onSettings,
    this.otherHandle,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    final isOther = otherHandle != null;
    final handle = isOther ? otherHandle! : kMe.handle;
    final myPosts = posts.where((p) => isOther ? p.handle == handle : p.mine).toList();
    final myLikes = posts.where((p) => p.liked).toList();
    final myReplies = <MapEntry<Reply, Post>>[];
    for (final p in posts) {
      for (final r in p.replies) {
        if (isOther ? r.handle == handle : r.mine) myReplies.add(MapEntry(r, p));
      }
    }

    return Expanded(
      child: Column(children: [
        GlassAppBar(
          leading: isOther ? IconBtn(icon: Icons.arrow_back, onTap: () => onOpen(null, true)) : null,
          title: Text(isOther ? '@$handle' : 'Profile', style: t.display(size: 18, color: t.milk)),
          actions: [isOther ? const IconBtn(icon: Icons.more_horiz) : IconBtn(icon: Icons.settings_outlined, onTap: onSettings)],
        ),
        Expanded(
          child: ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Avatar(handle: handle, size: 78),
                const SizedBox(width: 18),
                Expanded(
                  child: Row(children: [
                    _stat(t, '${myPosts.length}', 'Posts'),
                    _stat(t, '${myReplies.length}', 'Replies'),
                    _stat(t, '${myLikes.length}', 'Likes'),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isOther ? 'Anonymous Tribemate' : kMe.name, style: t.display(size: 15, color: t.milk)),
                const SizedBox(height: 1),
                Text('@$handle', style: t.body(size: 12.5, weight: FontWeight.w700, color: t.inkDim)),
                const SizedBox(height: 6),
                Text('${kMe.flag} ${kMe.country}', style: t.body(size: 12, weight: FontWeight.w600, color: t.inkDim)),
                const SizedBox(height: 6),
                Text(kMe.bio, style: t.body(size: 13, weight: FontWeight.w500, color: t.inkDim)),
                const SizedBox(height: 12),
                Wrap(spacing: 6, runSpacing: 6, children: kAffiliations.map((a) => TribeChip(icon: a.icon, label: a.name)).toList()),
                const SizedBox(height: 14),
                if (!isOther)
                  ClayButtonSecondary(label: 'Edit profile', onTap: onEdit)
                else
                  ClayButtonSecondary(label: 'Block @$handle', textColor: t.danger, leading: Icon(Icons.block, size: 14, color: t.danger)),
                const SizedBox(height: 16),
              ]),
            ),
            Row(children: [
              _tabIcon(context, Icons.grid_view_rounded, 'posts'),
              _tabIcon(context, Icons.chat_bubble_outline, 'replies'),
              _tabIcon(context, Icons.thumb_up_outlined, 'likes'),
            ]),
            const SizedBox(height: 4),
            if (tab == 'posts')
              myPosts.isEmpty
                  ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No posts yet.', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint))))
                  : _grid(myPosts),
            if (tab == 'replies')
              myReplies.isEmpty
                  ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No replies yet.', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint))))
                  : Column(children: myReplies.map((e) => _replyTile(context, e.key, e.value)).toList()),
            if (tab == 'likes')
              myLikes.isEmpty
                  ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No likes yet.', style: t.body(size: 13, weight: FontWeight.w600, color: t.inkFaint))))
                  : _grid(myLikes),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(TribeTheme t, String num, String label) => Expanded(
        child: Column(children: [
          Text(num, style: t.display(size: 17, color: t.milk)),
          const SizedBox(height: 2),
          Text(label, style: t.caption(size: 11)),
        ]),
      );

  Widget _tabIcon(BuildContext context, IconData icon, String id) {
    final t = TribeThemeScope.of(context);
    final active = tab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setTab(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line), bottom: BorderSide(color: active ? t.gold : t.line, width: active ? 2 : 1))),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: active ? t.milk : t.inkFaint),
        ),
      ),
    );
  }

  Widget _grid(List<Post> items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(3),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
        itemCount: items.length,
        itemBuilder: (context, i) => IgTile(post: items[i], onOpen: () => onOpen(items[i])),
      );

  Widget _replyTile(BuildContext context, Reply r, Post parent) {
    final t = TribeThemeScope.of(context);
    final preview = parent.content.length > 60 ? '${parent.content.substring(0, 60)}…' : parent.content;
    return GestureDetector(
      onTap: () => onOpen(parent),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: t.bg2, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: colorForHandle(r.handle), width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Replied to a post', style: t.caption(size: 11)),
          const SizedBox(height: 8),
          Text(r.content, style: t.body(size: 14.5, weight: FontWeight.w500, color: t.ink)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: t.grey700, width: 2))),
            child: Text(preview, style: t.body(size: 12, weight: FontWeight.w600, color: t.inkFaint)),
          ),
        ]),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  const EditProfileScreen({super.key, required this.onBack, required this.onSave});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: kMe.name);
    _bioCtrl = TextEditingController(text: kMe.bio);
    _bioCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.removeListener(_onChanged);
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Expanded(
      child: Column(children: [
        GlassAppBar(
          leading: IconBtn(icon: Icons.arrow_back, onTap: widget.onBack),
          title: Text('Edit profile', style: t.display(size: 18, color: t.milk)),
          // TODO: CONNECT — persist profile edits to your backend before calling onSave
          actions: [IconBtn(icon: Icons.check, color: t.gold, onTap: widget.onSave)],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(clipBehavior: Clip.none, children: [
                  const Avatar(handle: 'quietrebel22', size: 86),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [t.milk, t.milkDim]), shape: BoxShape.circle, boxShadow: t.clayMilkOut),
                      alignment: Alignment.center,
                      child: Icon(Icons.camera_alt, size: 12, color: t.bg0),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Text('Display name', style: t.caption(size: 11.5)),
              const SizedBox(height: 6),
              ClayInput(controller: _nameCtrl),
              const SizedBox(height: 18),
              Text('Bio', style: t.caption(size: 11.5)),
              const SizedBox(height: 6),
              ClayInput(controller: _bioCtrl, maxLines: 3, maxLength: 150),
              Align(alignment: Alignment.centerRight, child: Text('${_bioCtrl.text.length}/150', style: t.caption(size: 11))),
              const SizedBox(height: 18),
              Text('Affiliations', style: t.caption(size: 11.5)),
              const SizedBox(height: 6),
              for (final a in kAffiliations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(a.icon, size: 16, color: t.inkDim),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.name, style: t.body(size: 13.5, weight: FontWeight.w600, color: t.ink))),
                    Icon(Icons.close, size: 14, color: t.inkFaint),
                  ]),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class BlockedScreen extends StatelessWidget {
  final VoidCallback onBack;
  final List<String> blocked;
  final ValueChanged<String> onUnblock;
  const BlockedScreen({super.key, required this.onBack, required this.blocked, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Expanded(
      child: Column(children: [
        GlassAppBar(leading: IconBtn(icon: Icons.arrow_back, onTap: onBack), title: Text('Blocked', style: t.display(size: 18, color: t.milk))),
        Expanded(
          child: blocked.isEmpty
              ? const EmptyState(icon: Icons.block, headline: 'No blocked accounts')
              : ListView(
                  children: blocked
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            child: Row(children: [
                              Avatar(handle: h, size: 34),
                              const SizedBox(width: 12),
                              Expanded(child: Text('@$h', style: t.body(size: 13.5, weight: FontWeight.w800, color: t.ink))),
                              TribeChip(label: 'Unblock', onTap: () => onUnblock(h)),
                            ]),
                          ))
                      .toList(),
                ),
        ),
      ]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onBlocked;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;
  final bool isDark;
  final VoidCallback onToggleTheme;
  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onBlocked,
    required this.onSignOut,
    required this.onDelete,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);

    Widget group(String title) => Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), child: Text(title.toUpperCase(), style: t.caption(size: 10.5)));

    Widget row({required IconData icon, required String label, Color? color, VoidCallback? onTap, Widget? trailing}) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
            child: Row(children: [
              Icon(icon, size: 17, color: color ?? t.ink),
              const SizedBox(width: 13),
              Expanded(child: Text(label, style: t.body(size: 14, weight: FontWeight.w700, color: color ?? t.ink))),
              if (trailing != null) trailing,
            ]),
          ),
        );

    return Expanded(
      child: Column(children: [
        GlassAppBar(leading: IconBtn(icon: Icons.arrow_back, onTap: onBack), title: Text('Settings', style: t.display(size: 18, color: t.milk))),
        Expanded(
          child: ListView(children: [
            group('Appearance'),
            row(icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined, label: isDark ? 'Dark mode' : 'Light mode', onTap: onToggleTheme, trailing: MiniToggle(on: !isDark)),
            group('Privacy'),
            row(icon: Icons.block, label: 'Blocked accounts', onTap: onBlocked, trailing: Icon(Icons.chevron_right, size: 16, color: t.inkFaint)),
            group('Account'),
            // TODO: CONNECT — wire to your real sign-out flow
            row(icon: Icons.logout, label: 'Sign out', onTap: onSignOut),
            // TODO: CONNECT — wire to your real account-deletion flow
            row(icon: Icons.delete_outline, label: 'Delete account', color: t.danger, onTap: onDelete),
          ]),
        ),
      ]),
    );
  }
}

/* ============================================================================
   MODALS
   ============================================================================ */

class ReportModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSubmit;
  const ReportModal({super.key, required this.onClose, required this.onSubmit});
  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _choice;
  static const _options = ['Spam', 'Harassment', 'Hate speech', 'Nudity', 'Other'];

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.55),
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
                Expanded(child: ClayButtonSecondary(label: 'Cancel', onTap: widget.onClose)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClayButtonPrimary(
                    label: 'Submit',
                    onTap: _choice == null
                        ? null
                        : () {
                            widget.onSubmit();
                            widget.onClose();
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
        color: Colors.black.withOpacity(0.55),
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
                            onClose();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: t.dangerTint, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.danger.withOpacity(0.35))),
                            child: Text(confirmLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5, color: t.danger)),
                          ),
                        )
                      : ClayButtonPrimary(
                          label: confirmLabel,
                          onTap: () {
                            onConfirm();
                            onClose();
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

/* ============================================================================
   APP SHELL
   ============================================================================ */

enum Stage { splash, auth, onboarding, main }

class TribeGlass extends StatefulWidget {
  const TribeGlass({super.key});
  @override
  State<TribeGlass> createState() => _TribeGlassState();
}

class _TribeGlassState extends State<TribeGlass> {
  bool isDark = true;
  Stage stage = Stage.splash;
  int obPage = 0;
  final ObData ob = ObData();
  bool signingIn = false;
  TribeTab tab = TribeTab.home;
  late List<Post> posts;
  Post? detail;
  String? otherUserHandle;
  bool showCreate = false;
  String? snackbarText;
  int? poppedId;
  String profileTab = 'posts';
  bool showEdit = false;
  bool showSettings = false;
  bool showBlocked = false;
  List<String> blocked = ['campusferal'];
  dynamic reportTarget;
  Map<String, dynamic>? confirm; // {'type': 'signout' | 'delete'}

  Timer? _splashTimer;
  Timer? _snackTimer;
  Timer? _popTimer;

  @override
  void initState() {
    super.initState();
    posts = buildInitialPosts();
    _splashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && stage == Stage.splash) setState(() => stage = Stage.auth);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _snackTimer?.cancel();
    _popTimer?.cancel();
    super.dispose();
  }

  void _showSnackbar(String text) {
    setState(() => snackbarText = text);
    _snackTimer?.cancel();
    _snackTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => snackbarText = null);
    });
  }

  void _pop(int id) {
    setState(() => poppedId = id);
    _popTimer?.cancel();
    _popTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => poppedId = null);
    });
  }

  // TODO: CONNECT — replace local mutation with your real like/unlike API call
  void _likePost(int id) {
    _pop(id);
    setState(() {
      for (final p in posts) {
        if (p.id == id) {
          p.liked = !p.liked;
          p.likes += p.liked ? 1 : -1;
        }
      }
      if (detail?.id == id) {
        detail!.liked = !detail!.liked;
      }
    });
  }

  // TODO: CONNECT — replace local mutation with your real like/unlike API call
  void _likeReply(int postId, int replyId) {
    _pop(replyId);
    setState(() {
      for (final p in posts) {
        if (p.id != postId) continue;
        for (final r in p.replies) {
          if (r.id == replyId) {
            r.liked = !r.liked;
            r.likes += r.liked ? 1 : -1;
          }
        }
      }
    });
  }

  // TODO: CONNECT — replace with a real reply-submission API call
  void _sendReply(int postId, String text) {
    final newReply = Reply(id: DateTime.now().millisecondsSinceEpoch, handle: kMe.handle, time: 'now', content: text, likes: 0, liked: false, mine: true);
    setState(() {
      for (final p in posts) {
        if (p.id == postId) p.replies.insert(0, newReply);
      }
    });
    _showSnackbar('Reply sent');
  }

  // TODO: CONNECT — replace with a real post-creation API call
  void _createPost(String text, bool hasImage) {
    final newPost = Post(id: DateTime.now().millisecondsSinceEpoch, handle: kMe.handle, time: 'now', content: text, image: hasImage, likes: 0, liked: false, mine: true, replies: []);
    setState(() {
      posts.insert(0, newPost);
      showCreate = false;
    });
    _showSnackbar('Post published');
  }

  void _openPost(Post? post, [bool back = false]) {
    if (back) {
      setState(() => otherUserHandle = null);
      return;
    }
    setState(() => detail = post);
  }

  void _openAvatar(Post post) {
    if (post.handle == kMe.handle) {
      setState(() {
        tab = TribeTab.profile;
        otherUserHandle = null;
      });
      return;
    }
    setState(() {
      otherUserHandle = post.handle;
      tab = TribeTab.profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = TribeTheme(isDark);
    Widget body;

    if (stage == Stage.splash) {
      body = const SplashScreen();
    } else if (stage == Stage.auth) {
      body = AuthScreen(
        loading: signingIn,
        // TODO: CONNECT — wire to your real Google sign-in flow
        onSignIn: () {
          setState(() => signingIn = true);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              setState(() {
                signingIn = false;
                stage = Stage.onboarding;
              });
            }
          });
        },
      );
    } else if (stage == Stage.onboarding) {
      body = OnboardingScreen(
        page: obPage,
        setPage: (p) => setState(() => obPage = p),
        ob: ob,
        onJoin: () => setState(() => stage = Stage.main),
      );
    } else if (detail != null) {
      body = PostDetailScreen(
        post: detail!,
        onBack: () => setState(() => detail = null),
        onLikePost: _likePost,
        onLikeReply: _likeReply,
        onSend: _sendReply,
        onMenu: (target, [isReply = false]) => setState(() => reportTarget = target),
        poppedId: poppedId,
      );
    } else if (showEdit) {
      body = EditProfileScreen(
        onBack: () => setState(() => showEdit = false),
        onSave: () {
          setState(() => showEdit = false);
          _showSnackbar('Profile saved');
        },
      );
    } else if (showBlocked) {
      body = BlockedScreen(
        onBack: () => setState(() {
          showBlocked = false;
          showSettings = true;
        }),
        blocked: blocked,
        onUnblock: (h) => setState(() => blocked = blocked.where((b) => b != h).toList()),
      );
    } else if (showSettings) {
      body = SettingsScreen(
        onBack: () => setState(() => showSettings = false),
        onBlocked: () => setState(() {
          showSettings = false;
          showBlocked = true;
        }),
        onSignOut: () => setState(() => confirm = {'type': 'signout'}),
        onDelete: () => setState(() => confirm = {'type': 'delete'}),
        isDark: isDark,
        onToggleTheme: () => setState(() => isDark = !isDark),
      );
    } else {
      switch (tab) {
        case TribeTab.home:
          body = HomeScreen(posts: posts, onLike: _likePost, onOpen: _openPost, onAvatar: _openAvatar, onMenu: (p) => setState(() => reportTarget = p), poppedId: poppedId);
          break;
        case TribeTab.search:
          body = SearchScreen(posts: posts);
          break;
        case TribeTab.inbox:
          body = const InboxScreen(notifs: kNotifs);
          break;
        case TribeTab.profile:
          body = ProfileScreen(
            posts: posts,
            tab: profileTab,
            setTab: (v) => setState(() => profileTab = v),
            onOpen: _openPost,
            onEdit: () => setState(() => showEdit = true),
            onSettings: () => setState(() => showSettings = true),
            otherHandle: otherUserHandle,
          );
          break;
        case TribeTab.create:
          body = const SizedBox.shrink();
          break;
      }
    }

    final showBottomNav = stage == Stage.main && detail == null && !showEdit && !showBlocked && !showSettings;

    return TribeThemeScope(
      theme: t,
      child: Container(
        color: t.bg1,
        child: Stack(children: [
          Column(children: [
            const TribeStatusBar(),
            body,
            if (showBottomNav)
              BottomNavBar(
                tab: tab,
                onTab: (v) => setState(() {
                  tab = v;
                  otherUserHandle = null;
                }),
                onCreate: () => setState(() => showCreate = true),
              ),
            if (stage == Stage.main) const GestureBar(),
          ]),
          if (showCreate) Positioned.fill(child: CreatePostSheet(onClose: () => setState(() => showCreate = false), onPost: _createPost)),
          if (reportTarget != null)
            Positioned.fill(child: ReportModal(onClose: () => setState(() => reportTarget = null), onSubmit: () => _showSnackbar('Report submitted'))),
          if (confirm != null && confirm!['type'] == 'signout')
            Positioned.fill(
              child: ConfirmModal(
                title: 'Sign out?',
                body: 'You can sign back in anytime with the same Google account.',
                confirmLabel: 'Sign out',
                onClose: () => setState(() => confirm = null),
                onConfirm: () => setState(() => stage = Stage.auth),
              ),
            ),
          if (confirm != null && confirm!['type'] == 'delete')
            Positioned.fill(
              child: ConfirmModal(
                title: 'Delete account?',
                body: "This permanently erases your posts, replies, likes, and notifications. This can't be undone.",
                confirmLabel: 'Delete forever',
                danger: true,
                onClose: () => setState(() => confirm = null),
                onConfirm: () => setState(() => stage = Stage.auth),
              ),
            ),
          if (snackbarText != null) Positioned(left: 18, right: 18, bottom: 96, child: TribeSnackbar(text: snackbarText!)),
        ]),
      ),
    );
  }
}
