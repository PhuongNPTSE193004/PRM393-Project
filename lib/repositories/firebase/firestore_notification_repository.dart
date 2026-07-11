import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification.dart';
import '../notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  @override
  Stream<List<AppNotification>> getNotifications(String userId) {
    return _notifications
        .where('user_id', whereIn: [userId, 'all'])
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
      // Sort descending in-memory by createdAt
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return _notifications
        .where('user_id', whereIn: [userId, 'all'])
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'read': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final unreadSnap = await _notifications
        .where('user_id', whereIn: [userId, 'all'])
        .where('read', isEqualTo: false)
        .get();

    if (unreadSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in unreadSnap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    }
  }
}
