import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tribe_design.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

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
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.milk, t.milkDim], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: blobRadius(84, 84),
                      boxShadow: t.clayMilkOut,
                    ),
                    alignment: Alignment.center,
                    child: Text('T', style: t.display(size: 26, color: t.bg0)),
                  ),
                ),
                const SizedBox(height: 12),
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