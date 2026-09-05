import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/obsidian_tokens.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/obsidian/obsidian_dots.dart';
import '../../widgets/obsidian/obsidian_input.dart';
import '../../widgets/obsidian/obsidian_button.dart';

class OnboardingHandleScreen extends ConsumerStatefulWidget {
  const OnboardingHandleScreen({super.key});

  @override
  ConsumerState<OnboardingHandleScreen> createState() => _OnboardingHandleScreenState();
}

class _OnboardingHandleScreenState extends ConsumerState<OnboardingHandleScreen> {
  late final TextEditingController _controller;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObsidianTokens.bg0,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Row(children: [
              SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.arrow_back, color: ObsidianTokens.inkDim), onPressed: () => context.go('/onboarding/1'))),
              const Expanded(child: Center(child: ObsidianDots(count: 5, active: 2))),
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
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.alternate_email, size: 22, color: ObsidianTokens.gold),
                        const SizedBox(height: 18),
                        Text(
                          'Choose your identity',
                          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: ObsidianTokens.milk),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'This is how the tribe will know you.',
                          style: GoogleFonts.inter(fontSize: 12.5, color: ObsidianTokens.inkDim, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(onboardingProvider);
                      return ObsidianInput(
                        label: 'Display name',
                        controller: _nameController,
                        maxLength: 30,
                        showCounter: true,
                        hint: 'Anonymous Otter',
                        onChanged: (value) {
                          ref.read(onboardingProvider.notifier).setDisplayName(value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(onboardingProvider);
                      Widget? suffix;
                      String? errorText;
                      String? successText;
                      
                      if (state.availability == HandleAvailability.checking) {
                        suffix = const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ObsidianTokens.inkFaint));
                      } else if (state.availability == HandleAvailability.available) {
                        suffix = const Icon(Icons.check, size: 17, color: ObsidianTokens.success);
                        successText = '@${state.handleText} is yours.';
                      } else if (state.availability == HandleAvailability.taken) {
                        suffix = const Icon(Icons.close, size: 17, color: ObsidianTokens.danger);
                        errorText = "That handle's already claimed.";
                      } else if (state.availability == HandleAvailability.invalid) {
                        suffix = const Icon(Icons.close, size: 17, color: ObsidianTokens.danger);
                        errorText = 'Use at least 3 letters, numbers, or underscores.';
                      }
                      
                      return ObsidianInput(
                        label: 'Handle',
                        controller: _controller,
                        maxLength: 20,
                        onChanged: (value) {
                          ref.read(onboardingProvider.notifier).setHandle(value);
                        },
                        prefix: Text('@', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ObsidianTokens.inkFaint)),
                        suffix: suffix,
                        errorText: errorText,
                        successText: successText,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(onboardingProvider);
                      return ObsidianButton(
                        label: 'Next',
                        onPressed: (state.availability == HandleAvailability.available && state.displayNameText.trim().isNotEmpty && !state.saving)
                            ? () async {
                                await ref.read(onboardingProvider.notifier).saveHandle(ref);
                                await Future.delayed(const Duration(milliseconds: 50));
                                if (context.mounted) context.go('/onboarding/4');
                              }
                            : null,
                        loading: state.saving,
                      );
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
