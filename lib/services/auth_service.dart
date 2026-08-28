import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User user = userCredential.user!;

      // Check if user document exists
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;

      if (!userDoc.exists) {
        // Create new user document
        userModel = UserModel(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          avatarUrl: user.photoURL,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
      } else {
        // Parse existing user document
        userModel = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }

      return userModel;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set(UserModel(userId: user.uid, email: user.email ?? '', displayName: user.displayName ?? 'User', avatarUrl: user.photoURL, createdAt: DateTime.now()).toJson());
    }
  }
}