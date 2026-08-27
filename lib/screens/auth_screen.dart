import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth/google_sign_in_button.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Top 30%: TRIBE logo and tagline
              Column(
                children: [
                  Text(
                    'TRIBE',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where honesty is the algorithm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Center: Loading indicator or Google Sign-In Button
              if (authState is AuthLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                GoogleSignInButton(
                  onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                  isLoading: false,
                ),
              const SizedBox(height: 24),
              // Bottom: Terms and Privacy text
              Text(
                'By continuing, you agree to our Terms and Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}