import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:lottie/lottie.dart';
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
  String? _errorMessage;

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
    // Wait minimum 3 seconds for brand exposure (animation is 2.8s, +0.2s breathe on final frame)
    await Future.delayed(const Duration(seconds: 3));

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
        // Wrap post-auth network calls in a 5-second timeout to prevent hanging in Airplane mode
        await Future(() async {
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
        }).timeout(const Duration(seconds: 5));
      } on TimeoutException catch (_) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Connection failed. Please check your network.');
      } catch (e) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Connection failed. Please check your network.');
      }
    } else if (authState is AuthUnauthenticated) {
      context.go('/auth');
    } else {
      // Auth timed out or error - show error state
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection failed. Please check your network.');
    }
  }

  void _retryInitialization() {
    setState(() => _errorMessage = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
      _navigateAfterAuthReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    // INTENTIONAL: forced dark scope — splash screen is always black (brand screen).
    final t = const TribeTheme(true);
    return TribeThemeScope(
      theme: t,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Void #000000
        body: Stack(
          children: [
            // Lottie animation - full screen, aspect-fill
            if (_errorMessage == null)
              Lottie.asset(
                'assets/branding/TRIBE_Splash.json',
                fit: BoxFit.cover,
                repeat: false,
                animate: true,
              ),
            // Error state overlay (if any)
            if (_errorMessage != null)
              SafeArea(
                child: TribeErrorState(
                  message: _errorMessage!,
                  onRetry: _retryInitialization,
                ),
              ),
          ],
        ),
      ),
    );
  }
}