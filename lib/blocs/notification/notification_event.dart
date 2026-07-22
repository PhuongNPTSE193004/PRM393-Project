import 'package:equatable/equatable.dart';
import '../../models/app_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationSubscriptionRequested extends NotificationEvent {
  final String uid;
  const NotificationSubscriptionRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String notificationId;
  const NotificationMarkAsReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationsInternalChanged extends NotificationEvent {
  final List<AppNotification> notifications;
  const NotificationsInternalChanged(this.notifications);

  @override
  List<Object?> get props => [notifications];
}
