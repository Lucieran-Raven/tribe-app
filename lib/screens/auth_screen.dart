import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final t = const TribeTheme(true);

    // Listen to auth state changes and navigate accordingly
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
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

    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg1,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 54, 26, 34),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Column(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: t.lineStrong),
                      boxShadow: [BoxShadow(color: t.gold.withValues(alpha: 0.16), blurRadius: 34, spreadRadius: 2)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/logo/tribe_logo.png', width: 96, height: 96, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Wordmark(size: 30),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(color: t.bg2, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(100), boxShadow: t.clayOutSm),
                    child: Text('Where honesty is the algorithm', style: t.body(size: 12.5, weight: FontWeight.w700, color: t.inkDim)),
                  ),
                ]),
                Column(children: [
                  ClayButtonPrimary(
                    label: authState is AuthLoading ? 'Signing in…' : 'Continue with Google',
                    loading: authState is AuthLoading,
                    leading: authState is AuthLoading ? null : SvgPicture.asset('assets/google_g.svg', width: 16, height: 16),
                    onTap: _termsAccepted && authState is! AuthLoading ? () => ref.read(authProvider.notifier).signInWithGoogle() : null,
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                      activeColor: t.gold,
                      checkColor: t.bg0,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'I agree to the ', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkFaint)),
                          WidgetSpan(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TermsScreen())),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                child: Text('Terms', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim).copyWith(decoration: TextDecoration.underline)),
                              ),
                            ),
                          ),
                          TextSpan(text: ' and ', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkFaint)),
                          WidgetSpan(
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrivacyScreen())),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                child: Text('Privacy Policy', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkDim).copyWith(decoration: TextDecoration.underline)),
                              ),
                            ),
                          ),
                        ]),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ]),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}