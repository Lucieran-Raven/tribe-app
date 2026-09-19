import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/tribe_design.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends ConsumerState<OnboardingWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = TribeTheme(isDark);
    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Column(
            children: [
              // Header row with indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: 0,
                      child: IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/onboarding/1')),
                    ),
                    const OnboardingPageIndicator(activeIndex: 0),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              // Vertically centered cluster
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo container
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: t.lineStrong),
                            boxShadow: [BoxShadow(color: t.gold.withValues(alpha: 0.16), blurRadius: 34, spreadRadius: 2)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset('assets/logo/tribe_logo.png', width: 104, height: 104, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Headline
                        Text(
                          'Say the\nquiet part.',
                          textAlign: TextAlign.center,
                          style: t.display(size: 22, color: t.milk).copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 18),
                        // Description
                        SizedBox(
                          width: 250,
                          child: Text(
                            'TRIBE is where your campus tells the truth. Post rants and confessions you\'d never say under your real name.',
                            textAlign: TextAlign.center,
                            style: t.body(size: 13.5, weight: FontWeight.w500, color: t.inkDim).copyWith(height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Get Started button
                        ClayButtonPrimary(
                          label: 'Get started',
                          onTap: () => context.go('/onboarding/2'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
