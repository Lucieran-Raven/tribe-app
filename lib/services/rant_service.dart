import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rant_model.dart';
import '../models/reply_model.dart';

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
  }
}
