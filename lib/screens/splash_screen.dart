import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/obsidian_tokens.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/obsidian/organic_blob.dart';
import '../widgets/obsidian/wordmark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });

    // Navigate after 2 seconds based on auth state
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          context.go('/auth');
        } else {
          final authService = AuthService();
          await authService.ensureUserDoc();
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (!mounted) return;
          if (doc.exists && doc.data()?['handle'] != null && doc.data()?['handle'] != '') {
            context.go('/home');
          } else {
            context.go('/onboarding/1');
          }
        }
      } catch (e) {
        if (!mounted) return;
        context.go('/auth'); // Fallback to auth on any error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: ObsidianTokens.bg0,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OrganicBlob(
                size: 84,
                child: Text('T', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: ObsidianTokens.bg0)),
              ),
              const SizedBox(height: 6),
              const Wordmark(size: 30),
              const SizedBox(height: 8),
              Text('v1.0.0', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: ObsidianTokens.inkFaint, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}