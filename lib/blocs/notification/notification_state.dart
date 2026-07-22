import 'package:equatable/equatable.dart';
import '../../models/app_notification.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotification> notifications;
  final String? error;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, notifications, error];

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    String? error,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}
