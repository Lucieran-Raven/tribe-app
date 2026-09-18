import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/onesignal_keys.dart';

class PushService {
  static const String _appId = 'e98051a2-ef46-43f2-bf9d-90e2f9180263';
  static const String _apiKey = OneSignalKeys.restApiKey;
  static const String _apiUrl = 'https://api.onesignal.com/notifications';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendPush({
    required String targetUserId,
    required String title,
    required String body,
    String? targetRantId,
  }) async {
    // Don't send push if target is empty or invalid
    if (targetUserId.isEmpty) return;

    // Fetch target user's OneSignal playerId from Firestore
    final targetUserDoc = await _firestore.collection('users').doc(targetUserId).get();
    final playerId = (targetUserDoc.data()?['oneSignalPlayerId'] as String?) ?? '';

    if (playerId.isEmpty) {
      print('Push skipped: No playerId found for user $targetUserId');
      return;
    }

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
          'contents': {'en': body},
          'headings': {'en': title},
          'data': {
            if (targetRantId != null) 'targetRantId': targetRantId,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      print('=== PUSH SERVICE RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('Push failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Push error: $e');
    }
  }
}
