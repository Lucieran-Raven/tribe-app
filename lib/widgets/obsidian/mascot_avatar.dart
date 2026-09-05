import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../config/obsidian_tokens.dart';

class MascotAvatar extends StatelessWidget {
  final String handle;
  final double size;
  const MascotAvatar({super.key, required this.handle, this.size = 38});

  static int _hashOf(String str) {
    int h = 0;
    for (int i = 0; i < str.length; i++) h = str.codeUnitAt(i) + ((h << 5) - h);
    return h.abs();
  }

  static Color ringColorFor(String handle) => ObsidianTokens.mascotPalette[_hashOf(handle) % ObsidianTokens.mascotPalette.length];

  static Color _colorFor(String str) => ObsidianTokens.mascotPalette[_hashOf(str) % ObsidianTokens.mascotPalette.length];

  @override
  Widget build(BuildContext context) {
    final h = _hashOf(handle);
    final ringColor = ringColorFor(handle);
    final bodyIdx = h % 3;
    final faceIdx = (h ~/ 3) % 3;
    final topperIdx = (h ~/ 7) % 3;

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.36, -0.48), radius: 0.9,
          colors: [ObsidianTokens.bg4, ObsidianTokens.bg1],
        ),
        boxShadow: ObsidianTokens.clayOutSmDark,
        border: Border.all(color: ringColor.withOpacity(0.44), width: 1.5),
      ),
      padding: EdgeInsets.all(size * 0.09),
      child: CustomPaint(
        size: Size(size * 0.82, size * 0.82),
        painter: _MascotPainter(bodyIdx: bodyIdx, faceIdx: faceIdx, topperIdx: topperIdx, ringColor: ringColor),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final int bodyIdx, faceIdx, topperIdx;
  final Color ringColor;
  _MascotPainter({required this.bodyIdx, required this.faceIdx, required this.topperIdx, required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final bodyPaint = Paint()..color = const Color(0xFF242428)..style = PaintingStyle.fill;
    final bodyStroke = Paint()..color = ringColor..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeJoin = StrokeJoin.round;
    final faceStroke = Paint()..color = const Color(0xFF3A3A3F)..style = PaintingStyle.stroke..strokeWidth = 4 * s..strokeCap = StrokeCap.round;
    final eyeFill = Paint()..color = const Color(0xFF0F0F11)..style = PaintingStyle.fill;
    final eyeStroke = Paint()..color = const Color(0xFF3A3A3F)..style = PaintingStyle.stroke..strokeWidth = 3 * s;
    final pupilFill = Paint()..color = const Color(0xFFEDEAE2)..style = PaintingStyle.fill;

    // 3 BODY PATHS (verbatim from JSX)
    Path body;
    if (bodyIdx == 0) {
      body = Path()..moveTo(50*s, 8*s)..cubicTo(74*s, 8*s, 90*s, 26*s, 90*s, 50*s)..cubicTo(90*s, 74*s, 72*s, 92*s, 50*s, 92*s)..cubicTo(26*s, 92*s, 10*s, 76*s, 10*s, 50*s)..cubicTo(10*s, 26*s, 26*s, 8*s, 50*s, 8*s);
    } else if (bodyIdx == 1) {
      body = Path()..moveTo(50*s, 6*s)..cubicTo(70*s, 4*s, 92*s, 20*s, 94*s, 44*s)..cubicTo(96*s, 68*s, 80*s, 94*s, 52*s, 94*s)..cubicTo(24*s, 94*s, 6*s, 74*s, 8*s, 48*s)..cubicTo(10*s, 26*s, 30*s, 8*s, 50*s, 6*s);
    } else {
      body = Path()..moveTo(50*s, 10*s)..cubicTo(68*s, 6*s, 88*s, 14*s, 92*s, 36*s)..cubicTo(97*s, 60*s, 88*s, 88*s, 58*s, 92*s)..cubicTo(30*s, 96*s, 8*s, 78*s, 8*s, 52*s)..cubicTo(8*s, 30*s, 30*s, 14*s, 50*s, 10*s);
    }
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, bodyStroke);

    // 3 FACES
    if (faceIdx == 0) {
      canvas.drawCircle(Offset(36*s, 48*s), 10.5*s, eyeFill);
      canvas.drawCircle(Offset(36*s, 48*s), 10.5*s, eyeStroke);
      canvas.drawCircle(Offset(38*s, 50*s), 4*s, pupilFill);
      canvas.drawCircle(Offset(66*s, 48*s), 10.5*s, eyeFill);
      canvas.drawCircle(Offset(66*s, 48*s), 10.5*s, eyeStroke);
      canvas.drawCircle(Offset(68*s, 50*s), 4*s, pupilFill);
      final smile = Path()..moveTo(38*s, 66*s)..quadraticBezierTo(50*s, 76*s, 62*s, 66*s);
      canvas.drawPath(smile, faceStroke);
    } else if (faceIdx == 1) {
      final e1 = Path()..moveTo(28*s, 48*s)..quadraticBezierTo(36*s, 41*s, 44*s, 48*s);
      final e2 = Path()..moveTo(58*s, 48*s)..quadraticBezierTo(66*s, 41*s, 74*s, 48*s);
      final mouth = Path()..moveTo(42*s, 65*s)..quadraticBezierTo(50*s, 71*s, 58*s, 65*s);
      canvas.drawPath(e1, faceStroke); canvas.drawPath(e2, faceStroke); canvas.drawPath(mouth, faceStroke);
    } else {
      canvas.drawCircle(Offset(50*s, 46*s), 13*s, eyeFill);
      canvas.drawCircle(Offset(50*s, 46*s), 13*s, eyeStroke);
      canvas.drawCircle(Offset(53*s, 48*s), 5*s, pupilFill);
      canvas.drawLine(Offset(36*s, 68*s), Offset(64*s, 68*s), faceStroke);
    }

    // 3 TOPPERS
    if (topperIdx == 0) {
      final earPaint = Paint()..color = const Color(0xFF2B2B30)..style = PaintingStyle.fill;
      final earStroke = Paint()..color = ringColor..style = PaintingStyle.stroke..strokeWidth = 2.5*s;
      canvas.drawCircle(Offset(34*s, 14*s), 6*s, earPaint); canvas.drawCircle(Offset(34*s, 14*s), 6*s, earStroke);
      canvas.drawCircle(Offset(66*s, 14*s), 6*s, earPaint); canvas.drawCircle(Offset(66*s, 14*s), 6*s, earStroke);
    } else if (topperIdx == 1) {
      final hornPaint = Paint()..color = const Color(0xFF2B2B30)..style = PaintingStyle.fill;
      final hornStroke = Paint()..color = ringColor..style = PaintingStyle.stroke..strokeWidth = 2.5*s..strokeJoin = StrokeJoin.round;
      final horn = Path()..moveTo(50*s, 2*s)..lineTo(58*s, 20*s)..lineTo(42*s, 20*s)..close();
      canvas.drawPath(horn, hornPaint); canvas.drawPath(horn, hornStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => old.bodyIdx != bodyIdx || old.faceIdx != faceIdx || old.topperIdx != topperIdx;
}
