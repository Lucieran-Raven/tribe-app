import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
        builder: (context, state) => const OnboardingAvatarScreen(),
      ),
      GoRoute(
        path: '/onboarding/3',
        builder: (context, state) => const OnboardingHandleScreen(),
      ),
      GoRoute(
        path: '/onboarding/4',
        builder: (context, state) => const OnboardingCountryScreen(),
      ),
      GoRoute(
        path: '/onboarding/5',
        builder: (context, state) => const OnboardingAffiliationsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/rant/:id',
        builder: (context, state) {
          final rantId = state.pathParameters['id']!;
          return RantDetailScreen(rantId: rantId);
        },
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/blocked-accounts',
        builder: (context, state) => const BlockedAccountsScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
  );
});

// Export the router for backward compatibility
GoRouter get router => throw UnimplementedError('Use routerProvider instead');