import 'dart:convert';
import 'package:http/http.dart' as http;

class PushService {
  static const String _appId = 'e98051a2-ef46-43f2-bf9d-90e2f9180263';
  static const String _apiKey = 'os_v2_app_5gafdixpizb7fp45sdrpsgacmmklhs455wmuysvqj7qj6pcdwb5a7cy3oxliq6muimontcjxts5ahxhtztjk5hzfhdtxmx76cfw5kka';
  static const String _apiUrl = 'https://api.onesignal.com/notifications';

  Future<void> sendPush({
    required String targetUserId,
    required String title,
    required String body,
    String? targetRantId,
  }) async {
    // Don't send push if target is empty or invalid
    if (targetUserId.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_apiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_aliases': {
            'external_id': [targetUserId]
          },
          'target_channel': 'push',
          'contents': {'en': body},
          'headings': {'en': title},
          'data': {
            if (targetRantId != null) 'targetRantId': targetRantId,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      print('PUSH RESPONSE STATUS: ${response.statusCode}');
      print('PUSH RESPONSE BODY: ${response.body}');
      
      if (response.statusCode != 200) {
        print('Push failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Push error: $e');
    }
  }
}
