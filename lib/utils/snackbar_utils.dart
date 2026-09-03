import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

class TribeSnackBar {
  static void show(BuildContext context, String message, {SnackBarType type = SnackBarType.info}) {
    Color bgColor;
    IconData icon;
    switch (type) {
      case SnackBarType.success:
        bgColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        bgColor = const Color(0xFFC62828);
        icon = Icons.error_outline;
        break;
      case SnackBarType.info:
        bgColor = const Color(0xFF424242);
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
