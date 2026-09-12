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

  Future<String> createReply(ReplyModel reply) async {
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
    return docRef.id;
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
    final rantRef = _firestore.collection('rants').doc(rantId);
    final voteRef = _firestore.collection('rants').doc(rantId).collection('votes').doc(userId);
    
    final rantDoc = await rantRef.get();
    if (!rantDoc.exists) {
      throw Exception('Rant not found');
    }
    final rantOwnerId = rantDoc.data()?['userId'];
    final rantContent = rantDoc.data()?['content'] ?? '';
    final voterIds = List<String>.from(rantDoc.data()?['voterIds'] ?? []);
    final hasVoted = voterIds.contains(userId);

    final batch = _firestore.batch();
    if (hasVoted) {
      batch.update(rantRef, {
        'voterIds': FieldValue.arrayRemove([userId]),
        'karma': FieldValue.increment(-1),
      });
      batch.delete(voteRef);
    } else {
      batch.update(rantRef, {
        'voterIds': FieldValue.arrayUnion([userId]),
        'karma': FieldValue.increment(1),
      });
      batch.set(voteRef, {'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
    }
    await batch.commit();

    // Handle notifications
    try {
      if (rantOwnerId != null && userId != rantOwnerId) {
        final voterDoc = await _firestore.collection('users').doc(userId).get();
        final voterHandle = voterDoc.data()?['handle'] ?? 'anonymous';
        final voterAvatarUrl = voterDoc.data()?['avatarUrl'];

        if (!hasVoted) {
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
          await PushService().sendPush(
            targetUserId: rantOwnerId,
            title: 'New Like',
            body: '@$voterHandle liked your post',
            targetRantId: rantId,
          );
        } else {
          final deterministicId = 'karma_${rantId}_$userId';
          await NotificationService().deleteKarmaNotification(rantOwnerId, deterministicId);
        }
      }
    } catch (e) {
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
    final replyRef = _firestore.collection('rants').doc(rantId).collection('replies').doc(replyId);
    final voteRef = _firestore.collection('rants').doc(rantId).collection('replies').doc(replyId).collection('votes').doc(userId);
    
    final replyDoc = await replyRef.get();
    if (!replyDoc.exists) {
      throw Exception('Reply not found');
    }
    final replyOwnerId = replyDoc.data()?['userId'];
    final replyContent = replyDoc.data()?['content'] ?? '';
    final voterIds = List<String>.from(replyDoc.data()?['voterIds'] ?? []);
    final hasVoted = voterIds.contains(userId);

    final batch = _firestore.batch();
    if (hasVoted) {
      batch.update(replyRef, {
        'voterIds': FieldValue.arrayRemove([userId]),
        'karma': FieldValue.increment(-1),
      });
      batch.delete(voteRef);
    } else {
      batch.update(replyRef, {
        'voterIds': FieldValue.arrayUnion([userId]),
        'karma': FieldValue.increment(1),
      });
      batch.set(voteRef, {'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
    }
    await batch.commit();

    // Handle notifications
    try {
      if (replyOwnerId != null && userId != replyOwnerId) {
        final voterDoc = await _firestore.collection('users').doc(userId).get();
        final voterHandle = voterDoc.data()?['handle'] ?? 'anonymous';
        final voterAvatarUrl = voterDoc.data()?['avatarUrl'];

        if (!hasVoted) {
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
          await PushService().sendPush(
            targetUserId: replyOwnerId,
            title: 'New Like',
            body: '@$voterHandle liked your reply',
            targetRantId: rantId,
          );
        } else {
          final deterministicId = 'replyKarma_${replyId}_$userId';
          await NotificationService().deleteKarmaNotification(replyOwnerId, deterministicId);
        }
      }
    } catch (e) {
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
