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
    final t = const TribeTheme(true);
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
                        // Icon badge container
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: t.bg2,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: t.line),
                            boxShadow: t.clayOut,
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.groups_rounded, size: 30, color: t.gold),
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
