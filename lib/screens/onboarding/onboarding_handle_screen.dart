import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/tribe_design.dart';
import '../../providers/onboarding_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF), size: 24),
                    onPressed: () => context.go('/onboarding/1'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '03 / IDENTITY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                      color: const Color(0xFF8F8A8B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Headline
              Text(
                'CHOOSE YOUR IDENTITY.',
                style: GoogleFonts.anton(fontSize: 44, height: 1.05, color: const Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 8),
              // Subtext
              Text(
                'This is how the tribe will know you.',
                style: GoogleFonts.inter(fontSize: 16, height: 1.5, color: const Color(0xFF8F8A8B)),
              ),
              const SizedBox(height: 32),
              // Display name label
              Text(
                'DISPLAY NAME',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.0, color: const Color(0xFF8F8A8B)),
              ),
              const SizedBox(height: 8),
              // Display name input
              _V3Input(
                controller: _nameController,
                hint: 'Anonymous Otter',
                maxLength: 30,
                onChanged: (value) {
                  ref.read(onboardingProvider.notifier).setDisplayName(value);
                },
              ),
              const SizedBox(height: 6),
              // Display name counter
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_nameController.text.length}/30',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8F8A8B)),
                ),
              ),
              const SizedBox(height: 24),
              // Handle label
              Text(
                'HANDLE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 2.0, color: const Color(0xFF8F8A8B)),
              ),
              const SizedBox(height: 8),
              // Handle input
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(onboardingProvider);
                  Color? borderColor;
                  if (state.availability == HandleAvailability.available) {
                    borderColor = const Color(0xFF3FB27F);
                  }
                  if (state.availability == HandleAvailability.taken || state.availability == HandleAvailability.invalid) {
                    borderColor = const Color(0xFFFF5B3A);
                  }

                  return _V3Input(
                    controller: _controller,
                    hint: 'quietrebel22',
                    prefix: Text('@', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF8F8A8B))),
                    borderColorOverride: borderColor,
                    onChanged: (value) {
                      ref.read(onboardingProvider.notifier).setHandle(value);
                    },
                    suffix: state.availability == HandleAvailability.checking
                        ? const SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: Color(0xFF8F8A8B)))
                        : state.availability == HandleAvailability.available
                            ? const Icon(Icons.check, size: 17, color: Color(0xFF3FB27F))
                            : (state.availability == HandleAvailability.taken || state.availability == HandleAvailability.invalid)
                                ? const Icon(Icons.close, size: 17, color: Color(0xFFFF5B3A))
                                : null,
                  );
                },
              ),
              const SizedBox(height: 6),
              // Validation text
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(onboardingProvider);

                  if (state.availability == HandleAvailability.available) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            '@${state.handleText} is yours.',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3FB27F)),
                          ),
                        ),
                        Text(
                          '${state.handleText.length}/20',
                          style: GoogleFonts.inter(fontSize: 11, color: state.handleText.length > 20 ? const Color(0xFFFF5B3A) : const Color(0xFF8F8A8B)),
                        ),
                      ],
                    );
                  }
                  if (state.availability == HandleAvailability.taken) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            "That handle's already claimed.",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFF5B3A)),
                          ),
                        ),
                        Text(
                          '${state.handleText.length}/20',
                          style: GoogleFonts.inter(fontSize: 11, color: state.handleText.length > 20 ? const Color(0xFFFF5B3A) : const Color(0xFF8F8A8B)),
                        ),
                      ],
                    );
                  }
                  if (state.availability == HandleAvailability.invalid) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.handleError ?? 'Invalid handle.',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFF5B3A)),
                          ),
                        ),
                        Text(
                          '${state.handleText.length}/20',
                          style: GoogleFonts.inter(fontSize: 11, color: state.handleText.length > 20 ? const Color(0xFFFF5B3A) : const Color(0xFF8F8A8B)),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Spacer(),
              // Bottom button
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(onboardingProvider);
                    final enabled = state.availability == HandleAvailability.available && state.displayNameText.trim().isNotEmpty && !state.saving;

                    return _V3Button(
                      enabled: enabled,
                      saving: state.saving,
                      onTap: enabled
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

class _V3Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final Color? borderColorOverride;

  const _V3Input({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.borderColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1819),
        border: Border.all(color: borderColorOverride ?? const Color(0xFF2B2627), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Align(
                alignment: Alignment.center,
                heightFactor: 1.0,
                child: prefix,
              ),
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              onChanged: onChanged,
              style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFFF4F1F0)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF8F8A8B)),
                suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(left: 8), child: suffix) : null,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          if (suffix != null) const SizedBox(width: 8),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _V3Button extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final VoidCallback? onTap;

  const _V3Button({
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: saving
              ? const Color(0xFF1B1819)
              : enabled
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF1B1819),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: saving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF5E595A), strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(
                      'SAVING…',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.4, color: const Color(0xFF5E595A)),
                    ),
                  ],
                )
              : Text(
                  'NEXT',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: enabled ? const Color(0xFF0E0C0D) : const Color(0xFF5E595A),
                  ),
                ),
        ),
      ),
    );
  }
}
