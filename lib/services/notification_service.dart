import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), notificationId: doc.id))
            .toList());
  }

  Future<void> createNotification(String userId, NotificationModel notification) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();
    final notificationWithId = notification.copyWith(notificationId: docRef.id);
    await docRef.set(notificationWithId.toJson());
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
}
