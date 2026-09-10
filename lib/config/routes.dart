import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_welcome_screen.dart';
import '../screens/onboarding/onboarding_avatar_screen.dart';
import '../screens/onboarding/onboarding_handle_screen.dart';
import '../screens/onboarding/onboarding_affiliations_screen.dart';
import '../screens/onboarding/onboarding_country_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/rant_detail/rant_detail_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/legal/terms_screen.dart';
import '../screens/legal/privacy_screen.dart';
import '../screens/blocked_accounts_screen.dart';
import '../main.dart';

Widget _buildPageTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/onboarding/1',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingWelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/onboarding/2',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingAvatarScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/onboarding/3',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingHandleScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/onboarding/4',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingCountryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/onboarding/5',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingAffiliationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScaffold(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/rant/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RantDetailScreen(rantId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: UserProfileScreen(userId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/blocked-accounts',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BlockedAccountsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TermsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildPageTransition(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
    ],
  );
});

// Export the router for backward compatibility
GoRouter get router => throw UnimplementedError('Use routerProvider instead');