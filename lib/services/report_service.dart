import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reporterId,
    required String reason,
    String? snippet,
  }) async {
    final docId = 'report_${targetType}_${targetId}_${reporterId}';
    await _firestore.collection('reports').doc(docId).set({
      'targetType': targetType,
      'targetId': targetId,
      'reporterId': reporterId,
      'reason': reason,
      'snippet': snippet,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }
}
