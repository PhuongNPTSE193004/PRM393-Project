import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/chat/chat_bloc.dart';
import 'blocs/notification/notification_bloc.dart';
import 'blocs/order/order_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'repositories/chat_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firebase/firebase_auth_repository.dart';
import 'repositories/firebase/firestore_cart_repository.dart';
import 'repositories/firebase/firestore_chat_repository.dart';
import 'repositories/firebase/firestore_notification_repository.dart';
import 'repositories/firebase/firestore_order_repository.dart';
import 'repositories/firebase/firestore_product_repository.dart';
import 'repositories/firebase/firestore_user_repository.dart';
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

  // Repositories
  final authRepository = FirebaseAuthRepository();
  final userRepository = FirestoreUserRepository();
  final productRepository = FirestoreProductRepository();
  final cartRepository = FirestoreCartRepository(productRepository);
  final orderRepository = FirestoreOrderRepository();
  final notificationRepository = FirestoreNotificationRepository();
  final chatRepository = FirestoreChatRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<UserRepository>.value(value: userRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<CartRepository>.value(value: cartRepository),
        RepositoryProvider<OrderRepository>.value(value: orderRepository),
        RepositoryProvider<NotificationRepository>.value(value: notificationRepository),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: authRepository,
              userRepository: userRepository,
            )..add(AuthSubscriptionRequested()),
          ),
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(productRepository: productRepository),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(cartRepository: cartRepository),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(orderRepository: orderRepository),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(notificationRepository: notificationRepository),
          ),
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(chatRepository: chatRepository),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // Auto-seed initial catalog data asynchronously
  Future.microtask(() async {
    try {
      await SeedService().seedInitialData();
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
