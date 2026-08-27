import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      body: Center(
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
              child: Text(
                'TRIBE',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 200),
            Text(
              'v1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}