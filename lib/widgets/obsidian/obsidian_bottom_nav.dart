import 'package:flutter/material.dart';
import '../../config/obsidian_tokens.dart';
import 'glass_surface.dart';
import 'organic_blob.dart';

class ObsidianBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateTap;
  final int unreadCount;
  const ObsidianBottomNav({super.key, required this.currentIndex, required this.onTap, required this.onCreateTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    Widget _navItem(IconData icon, int idx) {
      final active = currentIndex == idx;
      return GestureDetector(
        onTap: () => onTap(idx),
        child: Container(
          width: 44, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: active ? ObsidianTokens.bg3 : Colors.transparent,
            boxShadow: active ? [const BoxShadow(color: Color(0x8C000000), offset: Offset(4,4), blurRadius: 9), const BoxShadow(color: Color(0x06FFFFFF), offset: Offset(-3,-3), blurRadius: 8)] : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: active ? ObsidianTokens.milk : ObsidianTokens.grey500),
        ),
      );
    }

    return GlassSurface(
      strong: true, topBorder: true,
      padding: EdgeInsets.fromLTRB(10, 10, 10, 8 + bottomInset),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
        _navItem(Icons.home_outlined, 0),
        _navItem(Icons.search, 1),
        // CENTER CREATE BLOB
        Transform.translate(
          offset: const Offset(0, -18),
          child: GestureDetector(
            onTap: onCreateTap,
            child: OrganicBlob(
              size: 48,
              child: const Icon(Icons.add, size: 20, color: ObsidianTokens.bg0),
            ),
          ),
        ),
        Stack(children: [
          _navItem(Icons.inbox_outlined, 2),
          if (unreadCount > 0) Positioned(top: 2, right: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: ObsidianTokens.gold, shape: BoxShape.circle))),
        ]),
        _navItem(Icons.person_outline, 3),
      ]),
    );
  }
}
