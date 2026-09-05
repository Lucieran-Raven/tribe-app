import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../config/obsidian_tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth/google_sign_in_button.dart';
import '../widgets/obsidian/organic_blob.dart';
import '../widgets/obsidian/wordmark.dart';
import '../widgets/obsidian/obsidian_button.dart';
import 'legal/terms_screen.dart';
import 'legal/privacy_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Listen to auth state changes and navigate accordingly
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!context.mounted) return;
          if (next.user.handle == null || next.user.handle!.isEmpty) {
            context.go('/onboarding/1');
          } else {
            context.go('/home');
          }
        });
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return Scaffold(
      body: Container(
        color: ObsidianTokens.bg0,
        padding: EdgeInsets.fromLTRB(26, 34, 26, 34 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            Column(
              children: [
                OrganicBlob(
                  size: 68,
                  child: Text('T', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: ObsidianTokens.bg0)),
                ),
                const SizedBox(height: 14),
                const Wordmark(size: 30),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: ObsidianTokens.bg2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: ObsidianTokens.line(false)),
                    boxShadow: ObsidianTokens.clayOutSmDark,
                  ),
                  child: Text('Where honesty is the algorithm', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: ObsidianTokens.inkDim)),
                ),
              ],
            ),
            Column(
              children: [
                if (authState is AuthLoading)
                  const Center(
                    child: CircularProgressIndicator(color: ObsidianTokens.milk),
                  )
                else
                  ObsidianButton(
                    label: 'Continue with Google',
                    onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                  ),
                const SizedBox(height: 18),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: ObsidianTokens.inkFaint),
                    children: [
                      const TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(text: 'Terms', style: TextStyle(color: ObsidianTokens.inkDim, decoration: TextDecoration.underline)),
                      const TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: TextStyle(color: ObsidianTokens.inkDim, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}