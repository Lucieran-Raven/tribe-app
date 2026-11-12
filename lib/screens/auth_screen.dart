import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/tribe_design.dart';
import '../providers/auth_provider.dart';
import 'legal/terms_screen.dart';
import 'legal/privacy_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // INTENTIONAL: forced dark scope — auth screen is always black (brand screen).
    final t = const TribeTheme(true);

    // Listen to auth state changes and navigate accordingly
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        if (!context.mounted) return;
        // Manually navigate based on onboarding status
        if (next.user.handle == null || next.user.handle!.isEmpty) {
          context.go('/onboarding/1');
        } else {
          context.go('/home');
        }
      } else if (next is AuthError) {
        Toast.error(context, next.message);
      }
    });

    // New design tokens
    const voidColor = Color(0xFF000000); // Void
    const boneColor = Color(0xFFF4F1F0); // Bone
    const whiteColor = Color(0xFFFFFFFF); // White
    const inkColor = Color(0xFF0E0C0D); // Ink
    const graphiteColor = Color(0xFF1B1819); // Graphite
    const lineColor = Color(0xFF2B2627); // Line
    const oxbloodColor = Color(0xFF6D001A); // Oxblood
    const disabledTextColor = Color(0xFF5E595A);

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: voidColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section: cropped auth mock + tagline
                Column(
                  children: [
                    const SizedBox(height: 20),
                    // ClipRect to show top ~45% of auth mock (wordmark only)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.45,
                        child: Image.asset(
                          'assets/branding/auth_mock.jpg',
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tagline text
                    Text(
                      'Where honesty is the algorithm',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: boneColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // Bottom section: interactive layer
                Column(
                  children: [
                    // Google button
                    GestureDetector(
                      onTap: _termsAccepted && authState is! AuthLoading
                          ? () => ref.read(authProvider.notifier).signInWithGoogle()
                          : null,
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _termsAccepted && authState is! AuthLoading
                              ? whiteColor
                              : graphiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: authState is AuthLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(inkColor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Signing in…',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: inkColor,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: _termsAccepted ? 1.0 : 0.4,
                                      child: SvgPicture.asset(
                                        'assets/google_g.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _termsAccepted ? inkColor : disabledTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Consent row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom checkbox
                        GestureDetector(
                          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _termsAccepted ? oxbloodColor : graphiteColor,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: lineColor,
                                width: 1,
                              ),
                            ),
                            child: _termsAccepted
                                ? const Icon(Icons.check, size: 16, color: whiteColor)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Consent text
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: 'I agree to the ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: boneColor,
                                ),
                              ),
                              WidgetSpan(
                                child: InkWell(
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => TermsScreen())),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Text(
                                      'Terms',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: boneColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: ' and ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: boneColor,
                                ),
                              ),
                              WidgetSpan(
                                child: InkWell(
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => PrivacyScreen())),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Text(
                                      'Privacy Policy',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: boneColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}