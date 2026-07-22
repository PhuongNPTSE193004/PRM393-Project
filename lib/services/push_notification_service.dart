import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background push notification: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Request notification permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User notification permission status: ${settings.authorizationStatus}');

    // 2. Setup Local Notification Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'airsoft_orders_channel',
      'Thông báo Đơn hàng Airsoft',
      description: 'Nhận cập nhật thời gian thực về trạng thái đơn hàng và ưu đãi.',
      importance: Importance.high,
    );

    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);

    await _localNotifs.initialize(initSettings);

    await _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 3. Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && !kIsWeb) {
        showLocalNotification(
          title: notification.title ?? 'Cập nhật đơn hàng',
          body: notification.body ?? 'Trạng thái đơn hàng của bạn đã thay đổi.',
        );
      }
    });

    // 5. Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
    });
  }

  /// Saves or updates the FCM Token for the authenticated user in Firestore
  Future<void> saveUserFcmToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Saved FCM Token for user $uid: $token');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Displays an immediate Heads-up Local Push Notification banner
  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'airsoft_orders_channel',
      'Thông báo Đơn hàng Airsoft',
      channelDescription: 'Nhận cập nhật thời gian thực về trạng thái đơn hàng.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _localNotifs.show(id, title, body, details);
  }

  /// Triggers order status push notification alert for a specific order
  Future<void> sendOrderStatusPushNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    
    String statusTitle = 'Cập nhật đơn hàng #$shortId';
    String statusBody = 'Đơn hàng #$shortId của bạn đã chuyển sang trạng thái: $status';

    if (status == 'paid') {
      statusBody = 'Đơn hàng #$shortId đã được thanh toán thành công!';
    } else if (status == 'shipped') {
      statusBody = 'Đơn hàng #$shortId đang trên đường giao đến bạn! 🚚';
    } else if (status == 'delivered') {
      statusBody = 'Đơn hàng #$shortId đã giao thành công. Cảm ơn bạn đã mua sắm! 🎉';
    } else if (status == 'cancelled') {
      statusBody = 'Đơn hàng #$shortId đã được hủy.';
    }

    // 1. Create Notification document in Firestore for user notification screen
    await _firestore.collection('notifications').add({
      'user_id': userId,
      'title': statusTitle,
      'body': statusBody,
      'kind': 'order',
      'order_id': orderId,
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    });

    // 2. Show local push notification banner
    await showLocalNotification(
      title: statusTitle,
      body: statusBody,
      id: orderId.hashCode,
    );
  }
}
