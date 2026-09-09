import 'package:flutter/material.dart';
import '../../design/tribe_design.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int activeIndex;
  final int totalPages;

  const OnboardingPageIndicator({
    super.key,
    required this.activeIndex,
    this.totalPages = 5,
  });

  @override
  Widget build(BuildContext context) {
    final t = TribeThemeScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: index == activeIndex ? t.gold : t.bg3,
            borderRadius: BorderRadius.circular(4),
            border: index == activeIndex ? null : Border.all(color: t.line),
          ),
        ),
      ),
    );
  }
}
