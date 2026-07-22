import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/customer/profile_screen.dart';
import 'services/push_notification_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM Push Notifications & Local Notification Channel
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Push notification init exception: $e');
  }

  runApp(const MyApp());

  // Auto-seed initial catalog data asynchronously after UI initializes
  Future.microtask(() async {
    try {
      await SeedService().seedInitialData(force: true);
    } catch (e) {
      debugPrint('Seed check exception: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
      routes: {'/profile': (_) => const CustomerProfileScreen()},
    );
  }
}
