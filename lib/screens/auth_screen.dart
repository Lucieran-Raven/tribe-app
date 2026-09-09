import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../design/tribe_design.dart';
import '../providers/auth_provider.dart';
import 'legal/terms_screen.dart';
import 'legal/privacy_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
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
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.milk, t.milkDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: blobRadius(68, 68),
                      boxShadow: t.clayMilkOut,
                    ),
                    alignment: Alignment.center,
                    child: Text('T', style: t.display(size: 22, color: t.bg0)),
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
                    onTap: authState is AuthLoading ? null : () => ref.read(authProvider.notifier).signInWithGoogle(),
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'By continuing you agree to our ', style: t.body(size: 11.5, weight: FontWeight.w600, color: t.inkFaint)),
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
                    textAlign: TextAlign.center,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}