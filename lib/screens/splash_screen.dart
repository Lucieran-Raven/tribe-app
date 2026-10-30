import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../design/tribe_design.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

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

    // Wait for BOTH minimum 2-second delay AND auth initialization
    _navigateAfterAuthReady();
  }

  Future<void> _navigateAfterAuthReady() async {
    // Wait minimum 2 seconds for brand exposure
    await Future.delayed(const Duration(seconds: 2));

    // Wait up to 5 more seconds for auth initialization (7 second total timeout)
    bool authReady = false;
    int attempts = 0;
    const maxAttempts = 50; // 50 * 100ms = 5 seconds

    while (!authReady && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated || authState is AuthUnauthenticated || authState is AuthError) {
        authReady = true;
      }
      attempts++;
    }

    if (!mounted) return;

    final authState = ref.read(authProvider);
    
    if (authState is AuthAuthenticated) {
      try {
        final user = authState.user;
        final authService = AuthService();
        await authService.ensureUserDoc();
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.userId).get();

        // Store OneSignal playerId in user document
        await OneSignal.login(user.userId);
        await NotificationService().syncPlayerId(user.userId);

        if (!mounted) return;
        if (doc.exists && doc.data()?['handle'] != null && doc.data()?['handle'] != '') {
          context.go('/home');
        } else {
          context.go('/onboarding/1');
        }
      } catch (e) {
        if (!mounted) return;
        context.go('/auth'); // Fallback to auth on error
      }
    } else if (authState is AuthUnauthenticated) {
      context.go('/auth');
    } else {
      // Auth timed out or error - fallback to auth
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    // INTENTIONAL: forced dark scope — splash screen is always black (brand screen).
    final t = const TribeTheme(true);
    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: t.bg0,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo/tribe_logo.png', width: 200, height: 200, fit: BoxFit.cover),
                const SizedBox(height: 20),
                const Wordmark(size: 30),
                const SizedBox(height: 6),
                Text('v1.0.0', style: t.caption(size: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}