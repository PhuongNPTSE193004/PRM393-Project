import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository,
        super(const NotificationState()) {
    on<NotificationSubscriptionRequested>(_onSubscriptionRequested);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationsInternalChanged>(_onInternalChanged);
  }

  Future<void> _onSubscriptionRequested(
    NotificationSubscriptionRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    await _notificationSubscription?.cancel();
    _notificationSubscription = _notificationRepository.getNotifications(event.uid).listen(
      (notifications) => add(NotificationsInternalChanged(notifications)),
      onError: (e) => emit(state.copyWith(status: NotificationStatus.failure, error: e.toString())),
    );
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);
    } catch (e) {
      // Potentially emit an error state or handle silently
    }
  }

  void _onInternalChanged(
    NotificationsInternalChanged event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      status: NotificationStatus.success,
      notifications: event.notifications,
    ));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
