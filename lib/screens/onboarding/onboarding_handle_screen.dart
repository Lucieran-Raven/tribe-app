import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding/onboarding_page_indicator.dart';

class OnboardingHandleScreen extends ConsumerStatefulWidget {
  const OnboardingHandleScreen({super.key});

  @override
  ConsumerState<OnboardingHandleScreen> createState() => _OnboardingHandleScreenState();
}

class _OnboardingHandleScreenState extends ConsumerState<OnboardingHandleScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error snackbar
    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.errorMsg != null && next.errorMsg != previous?.errorMsg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMsg!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding/1'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Icon(
                Icons.alternate_email,
                size: 120,
                color: AppTheme.brandPrimary,
              ),
              const SizedBox(height: 40),
              // Headline
              Text(
                'Pick a handle',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Body
              Text(
                'This is how people will know you in comments. Your rants stay anonymous.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // TextField - wrapped in Consumer for decoration only
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(onboardingProvider);
                  
                  return TextField(
                    controller: _controller,
                    onChanged: (value) {
                      ref.read(onboardingProvider.notifier).setHandle(value);
                    },
                    maxLength: 20,
                    decoration: InputDecoration(
                      prefixText: '@',
                      suffixIcon: _buildStatusIcon(state.availability),
                      counterText: '${_controller.text.length}/20',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: state.handleError ?? (state.availability == HandleAvailability.taken ? '@handle is taken' : null),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: state.handleError == null && state.availability == HandleAvailability.available
                              ? Colors.green
                              : AppTheme.brandPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: state.handleError == null && state.availability == HandleAvailability.available
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Consumer for "Available" text
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(onboardingProvider);
                  
                  if (state.handleError == null && state.availability == HandleAvailability.available) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Available',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),
              // Consumer for Next button
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(onboardingProvider);
                  
                  return ElevatedButton(
                    onPressed: state.availability == HandleAvailability.available && !state.saving
                        ? () async {
                            await ref.read(onboardingProvider.notifier).saveHandle(ref);
                            if (context.mounted) {
                              context.go('/onboarding/3');
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state.saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Next',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
              const Spacer(),
              // Page indicator
              const OnboardingPageIndicator(activeIndex: 1),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatusIcon(HandleAvailability availability) {
    switch (availability) {
      case HandleAvailability.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case HandleAvailability.available:
        return const Icon(Icons.check_circle, color: Colors.green);
      case HandleAvailability.taken:
      case HandleAvailability.invalid:
        return const Icon(Icons.error, color: Colors.red);
      case HandleAvailability.idle:
        return null;
    }
  }
}
