import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rant_model.dart';
import '../models/reply_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class RantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRant(RantModel rant) async {
    final docRef = _firestore.collection('rants').doc();
    final rantWithId = rant.copyWith(rantId: docRef.id);
    await docRef.set(rantWithId.toJson());
  }

  Stream<List<RantModel>> streamFeed() {
    return _firestore
        .collection('rants')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RantModel.fromJson(doc.data(), rantId: doc.id))
            .where((rant) => rant.isVisible)
            .toList());
  }

  Future<RantModel> getRant(String rantId) async {
    final doc = await _firestore.collection('rants').doc(rantId).get();
    if (!doc.exists) {
      throw Exception('Rant not found');
    }
    return RantModel.fromJson(doc.data()!, rantId: doc.id);
  }

  Stream<List<ReplyModel>> streamReplies(String rantId) {
    return _firestore
        .collection('rants')
        .doc(rantId)
        .collection('replies')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReplyModel.fromJson(doc.data(), replyId: doc.id))
            .toList());
  }

  Future<void> createReply(ReplyModel reply) async {
    final docRef = _firestore
        .collection('rants')
        .doc(reply.rantId)
        .collection('replies')
        .doc();
    final replyWithId = reply.copyWith(replyId: docRef.id);
    await docRef.set(replyWithId.toJson());
    await _firestore.collection('rants').doc(reply.rantId).update({
      'replyCount': FieldValue.increment(1),
    });

    // Create notification for rant owner
    try {
      final rantDoc = await _firestore.collection('rants').doc(reply.rantId).get();
      final ownerUserId = rantDoc.data()?['userId'];
      if (ownerUserId != null && reply.userId != ownerUserId) {
        // Fetch replier's user info
        final replierDoc = await _firestore.collection('users').doc(reply.userId).get();
        final replierHandle = replierDoc.data()?['handle'] ?? 'anonymous';
        final replierAvatarUrl = replierDoc.data()?['avatarUrl'];

        await NotificationService().createNotification(
          ownerUserId,
          NotificationModel(
            type: NotificationType.reply,
            fromUserId: reply.userId,
            fromHandle: replierHandle,
            fromAvatarUrl: replierAvatarUrl,
            targetRantId: reply.rantId,
            targetSnippet: reply.content,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Notification failure should not break the reply
      print('Failed to create notification: $e');
    }
  }

  Stream<bool> streamUserVote(String rantId, String userId) {
    return _firestore
        .collection('rants')
        .doc(rantId)
        .collection('votes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleVote(String rantId, String userId) async {
    // Fetch rant document to check ownership
    final rantDoc = await _firestore.collection('rants').doc(rantId).get();
    if (!rantDoc.exists) {
      throw Exception('Rant not found');
    }
    final rantOwnerId = rantDoc.data()?['userId'];

    bool wasVoted = false;
    await _firestore.runTransaction((transaction) async {
      final voteDocRef = _firestore
          .collection('rants')
          .doc(rantId)
          .collection('votes')
          .doc(userId);
      final rantDocRef = _firestore.collection('rants').doc(rantId);
      final voteDoc = await transaction.get(voteDocRef);

      if (voteDoc.exists) {
        wasVoted = true;
        transaction.delete(voteDocRef);
        transaction.update(rantDocRef, {'karma': FieldValue.increment(-1)});
      } else {
        wasVoted = false;
        transaction.set(voteDocRef, {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        transaction.update(rantDocRef, {'karma': FieldValue.increment(1)});
      }
    });

    // Handle notifications
    try {
      final rantContent = rantDoc.data()?['content'] ?? '';

      if (rantOwnerId != null && userId != rantOwnerId) {
        // Fetch voter's user info
        final voterDoc = await _firestore.collection('users').doc(userId).get();
        final voterHandle = voterDoc.data()?['handle'] ?? 'anonymous';
        final voterAvatarUrl = voterDoc.data()?['avatarUrl'];

        if (!wasVoted) {
          // Added vote - create notification
          final deterministicId = 'karma_${rantId}_${userId}';
          await NotificationService().upsertKarmaNotification(
            rantOwnerId,
            NotificationModel(
              type: NotificationType.karma,
              fromUserId: userId,
              fromHandle: voterHandle,
              fromAvatarUrl: voterAvatarUrl,
              targetRantId: rantId,
              targetSnippet: rantContent,
              timestamp: DateTime.now(),
            ),
            deterministicId,
          );
        } else {
          // Removed vote - delete notification
          final deterministicId = 'karma_${rantId}_${userId}';
          await NotificationService().deleteKarmaNotification(rantOwnerId, deterministicId);
        }
      }
    } catch (e) {
      // Notification failure should not break the vote
      print('Failed to handle notification: $e');
    }
  }

  Stream<bool> streamUserReplyVote(String rantId, String replyId, String userId) {
    return _firestore
        .collection('rants')
        .doc(rantId)
        .collection('replies')
        .doc(replyId)
        .collection('votes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleReplyVote(String rantId, String replyId, String userId) async {
    // Fetch reply document to check ownership
    final replyDoc = await _firestore
        .collection('rants')
        .doc(rantId)
        .collection('replies')
        .doc(replyId)
        .get();
    if (!replyDoc.exists) {
      throw Exception('Reply not found');
    }
    final replyOwnerId = replyDoc.data()?['userId'];

    bool wasVoted = false;
    await _firestore.runTransaction((transaction) async {
      final voteDocRef = _firestore
          .collection('rants')
          .doc(rantId)
          .collection('replies')
          .doc(replyId)
          .collection('votes')
          .doc(userId);
      final replyDocRef = _firestore
          .collection('rants')
          .doc(rantId)
          .collection('replies')
          .doc(replyId);
      final voteDoc = await transaction.get(voteDocRef);

      if (voteDoc.exists) {
        wasVoted = true;
        transaction.delete(voteDocRef);
        transaction.update(replyDocRef, {'karma': FieldValue.increment(-1)});
      } else {
        wasVoted = false;
        transaction.set(voteDocRef, {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        transaction.update(replyDocRef, {'karma': FieldValue.increment(1)});
      }
    });

    // Handle notifications
    try {
      final replyContent = replyDoc.data()?['content'] ?? '';

      if (replyOwnerId != null && userId != replyOwnerId) {
        // Fetch voter's user info
        final voterDoc = await _firestore.collection('users').doc(userId).get();
        final voterHandle = voterDoc.data()?['handle'] ?? 'anonymous';
        final voterAvatarUrl = voterDoc.data()?['avatarUrl'];

        if (!wasVoted) {
          // Added vote - create notification
          final deterministicId = 'replyKarma_${replyId}_${userId}';
          await NotificationService().upsertKarmaNotification(
            replyOwnerId,
            NotificationModel(
              type: NotificationType.replyKarma,
              fromUserId: userId,
              fromHandle: voterHandle,
              fromAvatarUrl: voterAvatarUrl,
              targetRantId: rantId,
              targetReplyId: replyId,
              targetSnippet: replyContent,
              timestamp: DateTime.now(),
            ),
            deterministicId,
          );
        } else {
          // Removed vote - delete notification
          final deterministicId = 'replyKarma_${replyId}_${userId}';
          await NotificationService().deleteKarmaNotification(replyOwnerId, deterministicId);
        }
      }
    } catch (e) {
      // Notification failure should not break the vote
      print('Failed to handle notification: $e');
    }
  }

  Future<UserModel> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromJson(doc.data()!);
  }

  Stream<List<RantModel>> streamUserRants(String userId) {
    return _firestore
        .collection('rants')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final rants = snapshot.docs
              .map((doc) => RantModel.fromJson(doc.data(), rantId: doc.id))
              .where((rant) => rant.isVisible)
              .toList();
          rants.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return rants;
        });
  }

  Stream<List<ReplyModel>> streamUserReplies(String userId) {
    return _firestore
        .collectionGroup('replies')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReplyModel.fromJson(doc.data(), replyId: doc.id))
            .toList());
  }
}
