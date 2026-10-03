import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String?> pendingNotificationRoute = ValueNotifier(null);

String? _notificationRoute(Map<String, dynamic>? data) {
  if (data == null) return null;
  final rantId = (data['targetRantId'] ?? data['rantId'] ?? data['postId'])?.toString();
  if (rantId == null || rantId.isEmpty) return null;
  final replyId = (data['targetReplyId'] ?? data['replyId'])?.toString();
  final params = <String, String>{'fromNotification': 'true'};
  if (replyId != null && replyId.isNotEmpty) params['targetReplyId'] = replyId;
  final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  return '/rant/${Uri.encodeComponent(rantId)}?$query';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('e98051a2-ef46-43f2-bf9d-90e2f9180263');

  OneSignal.User.pushSubscription.addObserver((state) {
    debugPrint('OneSignal subscription=${state.current.id} optedIn=${state.current.optedIn}');
  });

  OneSignal.Notifications.addClickListener((event) {
    final route = _notificationRoute(event.notification.additionalData);
    if (route != null) pendingNotificationRoute.value = route;
  });

  runApp(const ProviderScope(child: App()));
}
