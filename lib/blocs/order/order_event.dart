import 'package:equatable/equatable.dart';
import '../../models/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderSubscriptionRequested extends OrderEvent {
  final String? uid;
  const OrderSubscriptionRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}

class OrderPlaceRequested extends OrderEvent {
  final OrderModel order;
  const OrderPlaceRequested(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderCancelRequested extends OrderEvent {
  final String orderId;
  const OrderCancelRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderStatusUpdateRequested extends OrderEvent {
  final String orderId;
  final String newStatus;
  const OrderStatusUpdateRequested({required this.orderId, required this.newStatus});

  @override
  List<Object?> get props => [orderId, newStatus];
}

class OrdersInternalChanged extends OrderEvent {
  final List<OrderModel> orders;
  const OrdersInternalChanged(this.orders);

  @override
  List<Object?> get props => [orders];
}
