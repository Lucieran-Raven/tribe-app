import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<String?> pendingNotificationRoute = ValueNotifier(null);

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
    if (additionalData != null) {
      // Signal the MainScaffold to switch to Inbox tab
      pendingNotificationRoute.value = '/inbox';
    }
  });

  runApp(const ProviderScope(child: App()));
}
