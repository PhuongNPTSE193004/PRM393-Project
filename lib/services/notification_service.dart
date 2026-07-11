import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _repository;

  NotificationService(this._repository);

  Stream<List<AppNotification>> getNotifications(String userId) {
    return _repository.getNotifications(userId);
  }

  Stream<int> getUnreadCount(String userId) {
    return _repository.getUnreadCount(userId);
  }

  Future<void> markAsRead(String notificationId) {
    return _repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) {
    return _repository.markAllAsRead(userId);
  }
}
