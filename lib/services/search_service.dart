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
    if (query.isEmpty) {
      return [];
    }

    final snapshot = await _firestore
        .collection('rants')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    final lowerQuery = query.toLowerCase();
    final ranked = snapshot.docs
      .map((doc) => RantModel.fromJson(doc.data(), rantId: doc.id))
      .where((rant) => rant.content.toLowerCase().contains(lowerQuery))
      .toList();

    // Rank: exact phrase match first, then word-boundary match, then substring
    ranked.sort((a, b) {
      final aContent = a.content.toLowerCase();
      final bContent = b.content.toLowerCase();
      final aExact = aContent == lowerQuery ? 0 : (aContent.contains(' $lowerQuery ') || aContent.startsWith('$lowerQuery ')) ? 1 : 2;
      final bExact = bContent == lowerQuery ? 0 : (bContent.contains(' $lowerQuery ') || bContent.startsWith('$lowerQuery ')) ? 1 : 2;
      return aExact.compareTo(bExact);
    });
    return ranked;
  }
}
