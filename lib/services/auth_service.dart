import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

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
        // Parse existing user document - preserve existing avatarUrl and displayName
        final existingData = userDoc.data() as Map<String, dynamic>;
        userModel = UserModel.fromJson(existingData);
        
        // Only update email if it changed, but never overwrite avatarUrl or displayName
        if (user.email != null && userModel.email != user.email) {
          await _firestore.collection('users').doc(user.uid).update({'email': user.email});
          userModel = userModel.copyWith(email: user.email);
        }
      }

      // Link OneSignal to this Firebase user
      OneSignal.login(userModel.userId);
      OneSignal.User.addAlias("external_id", userModel.userId);

      // Sync OneSignal playerId for notifications
      await NotificationService().syncPlayerId(userModel.userId);

      return userModel;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await OneSignal.logout();
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
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

  Future<void> deleteAccount() async {
    final uid = _auth.currentUser!.uid;

    // 1. VOTES ON OTHERS' CONTENT (decrement parent karma)
    try {
      final votesQuery = await _firestore.collectionGroup('votes').where('userId', isEqualTo: uid).get();
      for (var i = 0; i < votesQuery.docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < votesQuery.docs.length) ? i + 500 : votesQuery.docs.length;
        for (var j = i; j < end; j++) {
          final voteRef = votesQuery.docs[j].reference;
          final parentRef = voteRef.parent.parent;
          if (parentRef != null) {
            batch.update(_firestore.doc(parentRef.path), {
              'karma': FieldValue.increment(-1),
              'voterIds': FieldValue.arrayRemove([uid]),
            });
          }
          batch.delete(voteRef);
        }
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('DELETE-STEP-FAIL step=1-batch-$i error=$e');
        }
      }
      debugPrint('DELETE-STEP-OK step=1');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=1 error=$e');
    }

    // 2. REPLIES (decrement parent replyCount)
    try {
      final repliesQuery = await _firestore.collectionGroup('replies').where('userId', isEqualTo: uid).get();
      for (var i = 0; i < repliesQuery.docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < repliesQuery.docs.length) ? i + 500 : repliesQuery.docs.length;
        for (var j = i; j < end; j++) {
          final replyRef = repliesQuery.docs[j].reference;
          final parentRef = replyRef.parent.parent;
          if (parentRef != null) {
            batch.update(_firestore.doc(parentRef.path), {'replyCount': FieldValue.increment(-1)});
          }
          batch.delete(replyRef);
        }
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('DELETE-STEP-FAIL step=2-batch-$i error=$e');
        }
      }
      debugPrint('DELETE-STEP-OK step=2');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=2 error=$e');
    }

    // 3. NOTIFICATIONS TRIGGERED BY USER (in others' inboxes)
    try {
      final trigNotifsQuery = await _firestore.collectionGroup('notifications').where('fromUserId', isEqualTo: uid).get();
      for (var i = 0; i < trigNotifsQuery.docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < trigNotifsQuery.docs.length) ? i + 500 : trigNotifsQuery.docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(trigNotifsQuery.docs[j].reference);
        }
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('DELETE-STEP-FAIL step=3-batch-$i error=$e');
        }
      }
      debugPrint('DELETE-STEP-OK step=3');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=3 error=$e');
    }

    // 4. USER'S OWN POSTS (with cascade cleanup)
    try {
      final postsQuery = await _firestore.collection('rants').where('userId', isEqualTo: uid).get();
      for (var rantIdx = 0; rantIdx < postsQuery.docs.length; rantIdx++) {
        final rantDoc = postsQuery.docs[rantIdx];
        final rantId = rantDoc.id;
        final rantPath = 'rants/$rantId';

        try {
          // 4a. Delete replies and their votes under this rant
          final repliesQuery = await _firestore.collection('rants').doc(rantId).collection('replies').get();
          for (var i = 0; i < repliesQuery.docs.length; i += 500) {
            final batch = _firestore.batch();
            final end = (i + 500 < repliesQuery.docs.length) ? i + 500 : repliesQuery.docs.length;
            for (var j = i; j < end; j++) {
              final replyDoc = repliesQuery.docs[j];
              final replyId = replyDoc.id;
              
              // Delete votes under this reply
              final replyVotesQuery = await _firestore.collection('rants').doc(rantId).collection('replies').doc(replyId).collection('votes').get();
              for (var k = 0; k < replyVotesQuery.docs.length; k += 500) {
                final voteBatch = _firestore.batch();
                final voteEnd = (k + 500 < replyVotesQuery.docs.length) ? k + 500 : replyVotesQuery.docs.length;
                for (var l = k; l < voteEnd; l++) {
                  voteBatch.delete(replyVotesQuery.docs[l].reference);
                }
                try {
                  await voteBatch.commit();
                } catch (e) {
                  debugPrint('DELETE-STEP-FAIL step=4a-reply-votes-$rantId-$replyId-$k error=$e');
                }
              }
              
              batch.delete(replyDoc.reference);
            }
            try {
              await batch.commit();
            } catch (e) {
              debugPrint('DELETE-STEP-FAIL step=4a-replies-$rantId-$i error=$e');
            }
          }

          // 4b. Delete votes directly under this rant
          final votesQuery = await _firestore.collection('rants').doc(rantId).collection('votes').get();
          for (var i = 0; i < votesQuery.docs.length; i += 500) {
            final batch = _firestore.batch();
            final end = (i + 500 < votesQuery.docs.length) ? i + 500 : votesQuery.docs.length;
            for (var j = i; j < end; j++) {
              batch.delete(votesQuery.docs[j].reference);
            }
            try {
              await batch.commit();
            } catch (e) {
              debugPrint('DELETE-STEP-FAIL step=4b-votes-$rantId-$i error=$e');
            }
          }

          // 4c. Delete the rant doc itself
          try {
            await _firestore.collection('rants').doc(rantId).delete();
          } catch (e) {
            debugPrint('DELETE-STEP-FAIL step=4c-rant-$rantPath error=$e');
          }
        } catch (e) {
          debugPrint('DELETE-STEP-FAIL step=4-rant-$rantPath error=$e');
        }
      }
      debugPrint('DELETE-STEP-OK step=4');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=4 error=$e');
    }

    // 5. USER'S OWN NOTIFICATIONS
    try {
      final userNotifsQuery = await _firestore.collection('users').doc(uid).collection('notifications').get();
      for (var i = 0; i < userNotifsQuery.docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < userNotifsQuery.docs.length) ? i + 500 : userNotifsQuery.docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(userNotifsQuery.docs[j].reference);
        }
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('DELETE-STEP-FAIL step=5-batch-$i error=$e');
        }
      }
      debugPrint('DELETE-STEP-OK step=5');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=5 error=$e');
    }

    // 6. ONESIGNAL LOGOUT (sever push notification tie before deletion)
    try {
      await OneSignal.logout();
      debugPrint('DELETE-STEP-OK step=6');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=6 error=$e');
    }

    // 7. USER DOC
    try {
      await _firestore.collection('users').doc(uid).delete();
      debugPrint('DELETE-STEP-OK step=7');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=7 error=$e');
    }

    // 8. AUTH ACCOUNT (LAST)
    try {
      await _auth.currentUser!.delete();
      debugPrint('DELETE-STEP-OK step=8');
    } catch (e) {
      debugPrint('DELETE-STEP-FAIL step=8 error=$e');
    }
  }
}