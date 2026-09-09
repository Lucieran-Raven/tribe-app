import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../design/tribe_design.dart';

class FullImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = const TribeTheme(true);
    return TribeThemeScope(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.bg0,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const CupertinoActivityIndicator(color: Colors.white),
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.broken_image_outlined, size: 40, color: Colors.white38),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.glassBgStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.lineStrong),
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
