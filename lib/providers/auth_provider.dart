import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthProvider extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthProvider(this._authService) : super(AuthInitial()) {
    // Don't auto-initialize - call initialize() explicitly
  }

  Future<void> initialize() async {
    state = AuthLoading();
    
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        state = AuthUnauthenticated();
        return;
      }

      // User is logged in, fetch their Firestore document
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        state = AuthAuthenticated(userModel);
      } else {
        // Create minimal user document
        final userModel = UserModel(
          userId: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? 'User',
          avatarUrl: currentUser.photoURL,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(currentUser.uid).set(userModel.toJson());
        state = AuthAuthenticated(userModel);
      }
    } catch (e) {
      print('Error initializing auth: $e');
      state = AuthUnauthenticated();
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    
    try {
      final UserModel? user = await _authService.signInWithGoogle();
      
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthUnauthenticated();
  }

  void updateUser(UserModel user) {
    state = AuthAuthenticated(user);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider(ref.watch(authServiceProvider));
});