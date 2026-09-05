import 'package:flutter/material.dart';

class ObsidianTokens {
  // DARK THEME
  static const Color bg0 = Color(0xFF08080A);
  static const Color bg1 = Color(0xFF121214);
  static const Color bg2 = Color(0xFF1A1A1D);
  static const Color bg3 = Color(0xFF222226);
  static const Color bg4 = Color(0xFF2B2B30);
  static const Color milk = Color(0xFFF3F0E8);
  static const Color milkDim = Color(0xFFE4E0D5);
  static const Color ink = Color(0xFFF3F1EC);
  static const Color inkDim = Color(0xFFA9A7A2);
  static const Color inkFaint = Color(0xFF6F6D6C);
  static const Color grey500 = Color(0xFF6E6C6A);
  static const Color grey700 = Color(0xFF47454A);
  static const Color gold = Color(0xFFD9AE6E);
  static const Color danger = Color(0xFFE96A5C);
  static const Color success = Color(0xFF74C79A);
  static const Color like = Color(0xFF34D399);

  static Color line(bool light) => light ? const Color(0x38141008) : const Color(0x12FFFFFF);
  static Color lineStrong(bool light) => light ? const Color(0x57141008) : const Color(0x24FFFFFF);

  // Mascot identity-ring palette (6 grey tones)
  static const List<Color> mascotPalette = [
    Color(0xFF8C8A85), Color(0xFF6E6C68), Color(0xFFA3A099),
    Color(0xFF5A5854), Color(0xFF95928A), Color(0xFF78766F),
  ];

  // Radii
  static const double radiusCard = 20;
  static const double radiusInput = 16;
  static const double radiusButton = 18;
  static const double radiusSheet = 34;
  static const double radiusModal = 28;
  static const double radiusChip = 100;
  static const double radiusCheckbox = 8;

  // Clay shadows (dark)
  static List<BoxShadow> clayOutDark = [
    const BoxShadow(color: Color(0x8C000000), offset: Offset(9, 9), blurRadius: 18),
    const BoxShadow(color: Color(0x09FFFFFF), offset: Offset(-7, -7), blurRadius: 15),
  ];
  static List<BoxShadow> clayOutSmDark = [
    const BoxShadow(color: Color(0x80000000), offset: Offset(5, 5), blurRadius: 11),
    const BoxShadow(color: Color(0x08FFFFFF), offset: Offset(-4, -4), blurRadius: 9),
  ];
  static List<BoxShadow> clayOutXsDark = [
    const BoxShadow(color: Color(0x73000000), offset: Offset(3, 3), blurRadius: 7),
    const BoxShadow(color: Color(0x08FFFFFF), offset: Offset(-2, -2), blurRadius: 5),
  ];
  static List<BoxShadow> clayMilkOutDark = [
    const BoxShadow(color: Color(0x66000000), offset: Offset(8, 8), blurRadius: 18),
    const BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-6, -6), blurRadius: 14),
  ];

  // Light theme variants
  static const Color lightBg0 = Color(0xFFF4EFE4);
  static const Color lightBg2 = Color(0xFFF1ECE1);
  static const Color lightBg3 = Color(0xFFE7E0D0);
  static const Color lightMilk = Color(0xFF1C1A16);
  static const Color lightInk = Color(0xFF201D18);
  static const Color lightInkDim = Color(0xFF5C574C);
  static const Color lightGold = Color(0xFF9C6B37);
}
