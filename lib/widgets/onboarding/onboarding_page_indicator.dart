import 'package:flutter/material.dart';
import '../../config/theme.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppTheme.brandPrimary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
