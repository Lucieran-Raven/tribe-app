import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _appId = 'e98051a2-ef46-43f2-bf9d-90e2f9180263';
  static const String _apiKey = 'os_v2_app_5gafdixpizb7fp45sdrpsgacmmklhs455wmuysvqj7qj6pcdwb5a7cy3oxliq6muimontcjxts5ahxhtztjk5hzfhdtxmx76cfw5kka';
  static const String _apiUrl = 'https://api.onesignal.com/notifications';

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          // One-time legacy cleanup: delete docs with non-deterministic IDs
          for (final doc in snapshot.docs) {
            final id = doc.id;
            if (!id.startsWith('like_') && !id.startsWith('reply_')) {
              try {
                doc.reference.delete();
              } catch (_) {}
            }
          }
          return snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data(), notificationId: doc.id))
              .toList();
        });
  }

  Future<void> createNotification(String userId, NotificationModel notification) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();
    final notificationWithId = notification.copyWith(notificationId: docRef.id);
    final data = notificationWithId.toJson();
    
    // Enforce custom notification icon
    data['android_small_icon'] = 'ic_notification';
    data['small_icon'] = 'ic_notification';
    
    await docRef.set(data);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }


  Future<void> deleteNotificationBySource(
    String userId,
    NotificationType type,
    String fromUserId,
    String targetRantId,
  ) async {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: type.name)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('targetRantId', isEqualTo: targetRantId)
        .limit(1);

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final query = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false);

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  Future<void> upsertKarmaNotification(String userId, NotificationModel notification, String deterministicId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(deterministicId);
    final notificationWithId = notification.copyWith(notificationId: docRef.id);
    await docRef.set(notificationWithId.toJson());
  }

  Future<void> deleteKarmaNotification(String userId, String deterministicId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(deterministicId)
        .delete();
  }

  Future<void> syncPlayerId(String uid) async {
    int attempts = 0;
    const maxAttempts = 6;
    
    while (attempts < maxAttempts) {
      try {
        final playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null && playerId.isNotEmpty) {
          await _firestore.collection('users').doc(uid).update({'oneSignalPlayerId': playerId});
          debugPrint('PLAYERID SYNCED for $uid (attempt ${attempts + 1})');
          return;
        }
        debugPrint('PLAYERID not ready for $uid (attempt ${attempts + 1})');
      } catch (e) {
        debugPrint('PLAYERID SYNC FAILED for $uid (attempt ${attempts + 1}): $e');
      }
      
      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    debugPrint('PLAYERID SYNC GAVE UP for $uid after $maxAttempts attempts');
  }

  Future<void> _sendPush({
    required String playerId,
    required String heading,
    required String content,
    required Map<String, dynamic> data,
  }) async {
    if (playerId.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_apiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_player_ids': [playerId],
          'headings': {'en': heading},
          'contents': {'en': content},
          'small_icon': 'ic_notification',
          'data': data,
        }),
      ).timeout(const Duration(seconds: 10));
      debugPrint('PUSH STATUS: ${response.statusCode}');
      debugPrint('PUSH BODY: ${response.body}');
    } catch (e) {
      debugPrint('PUSH FAILED: $e');
    }
  }

  // Like notification
  Future<void> sendLikeNotification({
    required String fromUserId,
    required String fromUsername,
    required String fromAvatarUrl,
    required String toUserId,
    required String rantId,
  }) async {
    if (fromUserId == toUserId) return; // Don't notify yourself

    // Fetch target user's OneSignal playerId
    final targetUserDoc = await _firestore.collection('users').doc(toUserId).get();
    final playerId = (targetUserDoc.data()?['oneSignalPlayerId'] as String?) ?? '';
    
    if (playerId.isEmpty) return; // Can't send notification without playerId

    // Use deterministic doc ID for upsert
    final docId = 'like_${fromUserId}_${toUserId}_${rantId}';
    final docRef = _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .doc(docId);

    // Create Firestore notification record (syncs with client-side notifications)
    await docRef.set(NotificationModel(
      notificationId: docId,
      type: NotificationType.karma,
      fromUserId: fromUserId,
      fromHandle: fromUsername,
      fromAvatarUrl: fromAvatarUrl,
      targetRantId: rantId,
      targetSnippet: 'Your rant',
      timestamp: DateTime.now(),
      isRead: false,
    ).toJson());

    // Send push notification via OneSignal REST API
    await _sendPush(
      playerId: playerId,
      heading: 'New Like',
      content: '@$fromUsername liked your rant',
      data: {'rantId': rantId, 'type': 'like', 'fromUserId': fromUserId},
    );
  }

  Future<void> deleteLikeNotification({
    required String fromUserId,
    required String toUserId,
    required String rantId,
  }) async {
    if (fromUserId == toUserId) return;
    final docId = 'like_$fromUserId\_$toUserId\_$rantId';
    await _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .doc(docId)
        .delete();
    debugPrint('DELETED LIKE NOTIFICATION $docId');
  }

  // Reply notification
  Future<void> sendReplyNotification({
    required String fromUserId,
    required String fromUsername,
    required String fromAvatarUrl,
    required String toUserId,
    required String rantId,
    required String replyContent,
  }) async {
    debugPrint('=== SEND REPLY NOTIFICATION ===');
    debugPrint('Target userId: $toUserId');

    if (fromUserId == toUserId) return; // Don't notify yourself

    // Fetch target user's OneSignal playerId
    final targetUserDoc = await _firestore.collection('users').doc(toUserId).get();
    final playerId = (targetUserDoc.data()?['oneSignalPlayerId'] as String?) ?? '';
    debugPrint('Target playerId: $playerId (empty: ${playerId.isEmpty})');
    
    if (playerId.isEmpty) return; // Can't send notification without playerId

    // Use deterministic doc ID for upsert
    final docId = 'reply_$fromUserId\_$toUserId\_$rantId';
    final docRef = _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .doc(docId);

    // Create Firestore notification record (syncs with client-side notifications)
    await docRef.set(NotificationModel(
      notificationId: docId,
      type: NotificationType.reply,
      fromUserId: fromUserId,
      fromHandle: fromUsername,
      fromAvatarUrl: fromAvatarUrl,
      targetRantId: rantId,
      targetSnippet: replyContent.length > 50 ? '${replyContent.substring(0, 50)}...' : replyContent,
      timestamp: DateTime.now(),
      isRead: false,
    ).toJson());

    debugPrint('About to call _sendPush...');

    // Send push notification via OneSignal REST API
    await _sendPush(
      playerId: playerId,
      heading: 'New Reply',
      content: '@$fromUsername replied to your rant',
      data: {'rantId': rantId, 'type': 'reply', 'fromUserId': fromUserId},
    );
  }

  Future<void> deleteReplyNotification({
    required String fromUserId,
    required String toUserId,
    required String rantId,
  }) async {
    if (fromUserId == toUserId) return;
    final docId = 'reply_$fromUserId\_$toUserId\_$rantId';
    await _firestore
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .doc(docId)
        .delete();
    debugPrint('DELETED REPLY NOTIFICATION $docId');
  }
}



