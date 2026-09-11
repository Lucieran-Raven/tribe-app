import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rant_model.dart';
import '../models/reply_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import 'push_service.dart';

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
        .orderBy('timestamp', descending: true)
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
          final deterministicId = 'karma_${rantId}_$userId';
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
          // Send push notification
          await PushService().sendPush(
            targetUserId: rantOwnerId,
            title: 'New Like',
            body: '@$voterHandle liked your post',
            targetRantId: rantId,
          );
        } else {
          // Removed vote - delete notification
          final deterministicId = 'karma_${rantId}_$userId';
          await NotificationService().deleteKarmaNotification(rantOwnerId, deterministicId);
        }
      }
    } catch (e) {
      // Notification failure should not break the vote
      debugPrint('Failed to handle notification: $e');
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
          final deterministicId = 'replyKarma_${replyId}_$userId';
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
          // Send push notification
          await PushService().sendPush(
            targetUserId: replyOwnerId,
            title: 'New Like',
            body: '@$voterHandle liked your reply',
            targetRantId: rantId,
          );
        } else {
          // Removed vote - delete notification
          final deterministicId = 'replyKarma_${replyId}_$userId';
          await NotificationService().deleteKarmaNotification(replyOwnerId, deterministicId);
        }
      }
    } catch (e) {
      // Notification failure should not break the vote
      debugPrint('Failed to handle notification: $e');
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

  Stream<List<RantModel>> streamUserLikes(String userId) {
    return _firestore
        .collectionGroup('votes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final rantIds = snapshot.docs.map((doc) => doc.reference.parent.parent!.id).toSet();
          if (rantIds.isEmpty) return <RantModel>[];
          final rants = <RantModel>[];
          for (final rantId in rantIds) {
            final rantDoc = await _firestore.collection('rants').doc(rantId).get();
            if (rantDoc.exists) {
              final rant = RantModel.fromJson(rantDoc.data()!, rantId: rantDoc.id);
              if (rant.isVisible) rants.add(rant);
            }
          }
          rants.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return rants;
        });
  }

  Future<UserModel> blockUser(String blockerId, String blockedId) async {
    await _firestore.collection('users').doc(blockerId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedId]),
    });
    final doc = await _firestore.collection('users').doc(blockerId).get();
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<UserModel> unblockUser(String blockerId, String blockedId) async {
    await _firestore.collection('users').doc(blockerId).update({
      'blockedUsers': FieldValue.arrayRemove([blockedId]),
    });
    final doc = await _firestore.collection('users').doc(blockerId).get();
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> deletePost(String rantId) async {
    final rantDoc = await _firestore.collection('rants').doc(rantId).get();
    if (!rantDoc.exists) return;
    final ownerId = rantDoc.data()?['userId'] as String?;

    // 1. Delete all replies under this post
    final repliesQuery = await _firestore.collection('rants').doc(rantId).collection('replies').get();
    for (var i = 0; i < repliesQuery.docs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < repliesQuery.docs.length) ? i + 500 : repliesQuery.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(repliesQuery.docs[j].reference);
      }
      await batch.commit();
    }

    // 2. Delete all votes on this post
    final votesQuery = await _firestore.collection('rants').doc(rantId).collection('votes').get();
    for (var i = 0; i < votesQuery.docs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < votesQuery.docs.length) ? i + 500 : votesQuery.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(votesQuery.docs[j].reference);
      }
      await batch.commit();
    }

    // 3. Delete all notifications targeting this post in the owner's inbox
    if (ownerId != null) {
      final notifsQuery = await _firestore.collection('users').doc(ownerId).collection('notifications').where('targetRantId', isEqualTo: rantId).get();
      for (var i = 0; i < notifsQuery.docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < notifsQuery.docs.length) ? i + 500 : notifsQuery.docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(notifsQuery.docs[j].reference);
        }
        await batch.commit();
      }
    }

    // 4. Finally, delete the post itself
    await _firestore.collection('rants').doc(rantId).delete();
  }

  Future<void> deleteReply(String rantId, String replyId) async {
    final replyRef = _firestore.collection('rants').doc(rantId).collection('replies').doc(replyId);
    final rantRef = _firestore.collection('rants').doc(rantId);
    final batch = _firestore.batch();
    batch.update(rantRef, {'replyCount': FieldValue.increment(-1)});
    batch.delete(replyRef);
    await batch.commit();
  }
}
