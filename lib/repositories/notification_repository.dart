import '../../models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> getNotifications(String userId);
  Stream<int> getUnreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
