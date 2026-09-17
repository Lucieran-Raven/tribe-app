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

          // Store OneSignal playerId in user document
          await OneSignal.login(user.uid);
          await NotificationService().syncPlayerId(user.uid);

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: t.lineStrong),
                    boxShadow: [BoxShadow(color: t.gold.withValues(alpha: 0.18), blurRadius: 44, spreadRadius: 4)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/logo/tribe_logo.png', width: 148, height: 148, fit: BoxFit.cover),
                  ),
                ),
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