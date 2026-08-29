import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

final userVoteProvider = StreamProvider.family<bool, String>((ref, rantId) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) {
    return Stream.value(false);
  }
  final userId = authState.user.userId;
  return FirebaseFirestore.instance
      .collection('rants')
      .doc(rantId)
      .collection('votes')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists);
});

final replyVoteProvider = StreamProvider.family<bool, (String, String)>((ref, ids) {
  final rantId = ids.$1;
  final replyId = ids.$2;
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value(false);
  final userId = authState.user.userId;
  return FirebaseFirestore.instance
      .collection('rants')
      .doc(rantId)
      .collection('replies')
      .doc(replyId)
      .collection('votes')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists);
});
