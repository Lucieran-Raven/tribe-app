import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rant_model.dart';
import '../models/user_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    final snapshot = await _firestore
        .collection('users')
        .where('handle', isGreaterThanOrEqualTo: lowerQuery)
        .where('handle', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  Future<List<RantModel>> searchRants(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Minimal search intentionally uses a small recent window. Firestore does
    // not provide arbitrary full-text search, so we avoid downloading the feed.
    final snapshot = await _firestore
        .collection('rants')
        .orderBy('timestamp', descending: true)
        .limit(40)
        .get();

    final results = snapshot.docs
        .map((doc) => RantModel.fromJson(doc.data(), rantId: doc.id))
        .where((rant) => rant.isVisible && rant.content.toLowerCase().contains(q))
        .toList();

    results.sort((a, b) {
      final ac = a.content.toLowerCase();
      final bc = b.content.toLowerCase();
      int rank(String s) => s == q ? 0 : (s.startsWith(q) ? 1 : (s.contains(' $q') ? 2 : 3));
      final c = rank(ac).compareTo(rank(bc));
      return c != 0 ? c : b.timestamp.compareTo(a.timestamp);
    });
    return results.take(20).toList();
  }
}
