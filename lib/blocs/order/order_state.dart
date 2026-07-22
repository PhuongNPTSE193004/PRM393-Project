import 'package:equatable/equatable.dart';
import '../../models/order.dart';

enum OrderStatus { initial, loading, success, failure }

class OrderState extends Equatable {
  final OrderStatus status;
  final List<OrderModel> orders;
  final String? error;

  const OrderState({
    this.status = OrderStatus.initial,
    this.orders = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, orders, error];

  OrderState copyWith({
    OrderStatus? status,
    List<OrderModel>? orders,
    String? error,
  }) {
    return OrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      error: error ?? this.error,
    );
  }
}
