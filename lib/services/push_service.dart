import 'package:cloud_functions/cloud_functions.dart';

class PushService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> sendPush({
    required String targetUserId,
    required String title,
    required String body,
    String? targetRantId,
    String? targetReplyId,
    String? type,
  }) async {
    if (targetUserId.isEmpty) return;
    try {
      await _functions.httpsCallable('sendPush').call({
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        if (targetRantId != null) 'targetRantId': targetRantId,
        if (targetReplyId != null) 'targetReplyId': targetReplyId,
        if (type != null) 'type': type,
      });
    } catch (_) {
      // Push failure must not fail the underlying social action.
    }
  }
}
