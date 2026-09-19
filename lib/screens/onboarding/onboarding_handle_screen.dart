import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/tribe_design.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';

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
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error snackbar
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        Toast.error(context, next.errorMsg!);
      }
    });

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
                    IconBtn(icon: Icons.arrow_back, onTap: () => context.go('/onboarding/1')),
                    const OnboardingPageIndicator(activeIndex: 2),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              // Headline
              Text(
                'Choose your identity',
                style: t.display(size: 18, color: t.milk),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Subtext
              Text(
                'This is how the tribe will know you.',
                style: t.body(size: 12.5, weight: FontWeight.w500, color: t.inkDim),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left-aligned gold icon
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.alternate_email, size: 22, color: t.gold),
                      ),
                      const SizedBox(height: 8),
                      // Display name caption
                      Text(
                        'Display name',
                        style: t.caption(size: 11.5, color: t.inkDim),
                      ),
                      const SizedBox(height: 6),
                      // Display name input
                      ClayInput(
                        controller: _nameController,
                        hint: 'Anonymous Otter',
                        onChanged: (value) {
                          ref.read(onboardingProvider.notifier).setDisplayName(value);
                        },
                      ),
                      // Display name counter
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${_nameController.text.length}/30', style: t.caption(size: 11)),
                      ),
                      const SizedBox(height: 18),
                      // Handle caption
                      Text(
                        'Handle',
                        style: t.caption(size: 11.5, color: t.inkDim),
                      ),
                      const SizedBox(height: 6),
                      // Handle input
                      Consumer(
                        builder: (context, ref, child) {
                          final state = ref.watch(onboardingProvider);
                          Color? borderColor;
                          if (state.availability == HandleAvailability.available) borderColor = t.success;
                          if (state.availability == HandleAvailability.taken || state.availability == HandleAvailability.invalid) borderColor = t.danger;
                          
                          return ClayInput(
                            controller: _controller,
                            hint: 'quietrebel22',
                            prefix: Text('@', style: t.body(size: 14, weight: FontWeight.w700, color: t.inkFaint)),
                            borderColorOverride: borderColor,
                            onChanged: (value) {
                              ref.read(onboardingProvider.notifier).setHandle(value);
                            },
                            suffix: state.availability == HandleAvailability.checking
                                ? SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: t.inkFaint))
                                : state.availability == HandleAvailability.available
                                    ? Icon(Icons.check, size: 17, color: t.success)
                                    : (state.availability == HandleAvailability.taken || state.availability == HandleAvailability.invalid)
                                        ? Icon(Icons.close, size: 17, color: t.danger)
                                        : null,
                          );
                        },
                      ),
                      // Validation text
                      Consumer(
                        builder: (context, ref, child) {
                          final state = ref.watch(onboardingProvider);
                          
                          if (state.availability == HandleAvailability.available) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '@${state.handleText} is yours.',
                                      style: t.body(size: 13, weight: FontWeight.w600, color: t.success),
                                    ),
                                  ),
                                  Text('${state.handleText.length}/20', style: t.caption(size: 11, color: state.handleText.length > 20 ? t.danger : t.inkFaint)),
                                ],
                              ),
                            );
                          }
                          if (state.availability == HandleAvailability.taken) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "That handle's already claimed.",
                                      style: t.body(size: 13, weight: FontWeight.w600, color: t.danger),
                                    ),
                                  ),
                                  Text('${state.handleText.length}/20', style: t.caption(size: 11, color: state.handleText.length > 20 ? t.danger : t.inkFaint)),
                                ],
                              ),
                            );
                          }
                          if (state.availability == HandleAvailability.invalid) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Use at least 3 letters, numbers, or underscores.',
                                      style: t.body(size: 13, weight: FontWeight.w600, color: t.danger),
                                    ),
                                  ),
                                  Text('${state.handleText.length}/20', style: t.caption(size: 11, color: state.handleText.length > 20 ? t.danger : t.inkFaint)),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(onboardingProvider);
                    
                    return ClayButtonPrimary(
                      label: 'Next',
                      onTap: state.availability == HandleAvailability.available && state.displayNameText.trim().isNotEmpty && !state.saving
                          ? () async {
                              await ref.read(onboardingProvider.notifier).saveHandle(ref);
                              if (context.mounted) {
                                context.go('/onboarding/4');
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
