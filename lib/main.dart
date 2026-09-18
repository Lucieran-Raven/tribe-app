import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:go_router/go_router.dart';
import 'app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? pendingNotificationRoute;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('e98051a2-ef46-43f2-bf9d-90e2f9180263');
  
  // Diagnostic Observer
  OneSignal.User.pushSubscription.addObserver((state) {
    print('=== ONESIGNAL DEVICE STATE ===');
    print('Subscription ID: ${state.current.id}');
    print('Push Token: ${state.current.token}');
    print('Opted In: ${state.current.optedIn}');
    print('==============================');
  });
  
  // Handle notification clicks
  OneSignal.Notifications.addClickListener((event) {
    final additionalData = event.notification.additionalData;
    if (additionalData != null && additionalData['targetRantId'] != null) {
      final rantId = additionalData['targetRantId'] as String;
      pendingNotificationRoute = '/rant/$rantId';
      
      // Try immediate navigation if context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null && pendingNotificationRoute != null) {
          GoRouter.of(context).push(pendingNotificationRoute!);
          pendingNotificationRoute = null;
        }
      });
    }
  });

  runApp(const ProviderScope(child: App()));
}
