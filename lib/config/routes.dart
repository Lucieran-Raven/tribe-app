import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_welcome_screen.dart';
import '../screens/onboarding/onboarding_handle_screen.dart';
import '../screens/onboarding/onboarding_affiliations_screen.dart';
import '../screens/main_scaffold.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;
  GoRouterRefreshStream(Stream stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null; // Never intercept splash

      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuth = state.matchedLocation == '/auth';

      // Bounce unauthenticated users out of protected routes
      if (!isLoggedIn && !isAuth) return '/auth';
      
      return null; 
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding/1',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/2',
        builder: (context, state) => const OnboardingHandleScreen(),
      ),
      GoRoute(
        path: '/onboarding/3',
        builder: (context, state) => const OnboardingAffiliationsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
    ],
  );
});

// Export the router for backward compatibility
GoRouter get router => throw UnimplementedError('Use routerProvider instead');