import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/obsidian_tokens.dart';
import '../../widgets/obsidian/obsidian_icon_badge.dart';
import '../../widgets/obsidian/obsidian_dots.dart';
import '../../widgets/obsidian/obsidian_button.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends ConsumerState<OnboardingWelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Row(children: [
              const SizedBox(width: 40),
              const Expanded(child: Center(child: ObsidianDots(count: 5, active: 0))),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  const ObsidianIconBadge(icon: Icons.people_outline),
                  const SizedBox(height: 18),
                  Text(
                    'Say the\nquiet part.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ObsidianTokens.milk,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "TRIBE is where your campus tells the truth. Post rants and confessions you'd never say under your real name.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: ObsidianTokens.inkDim,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ObsidianButton(
                    label: 'Get started',
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).reset();
                      context.go('/onboarding/2');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
