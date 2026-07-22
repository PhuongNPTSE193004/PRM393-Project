import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  StreamSubscription? _orderSubscription;

  OrderBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrderState()) {
    on<OrderSubscriptionRequested>(_onSubscriptionRequested);
    on<OrderPlaceRequested>(_onPlaceRequested);
    on<OrderCancelRequested>(_onCancelRequested);
    on<OrderStatusUpdateRequested>(_onStatusUpdateRequested);
    on<OrdersInternalChanged>(_onInternalChanged);
  }

  Future<void> _onSubscriptionRequested(
    OrderSubscriptionRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(status: OrderStatus.loading));
    await _orderSubscription?.cancel();
    _orderSubscription = _orderRepository.watchOrders(event.uid).listen(
      (orders) => add(OrdersInternalChanged(orders)),
      onError: (e) => emit(state.copyWith(status: OrderStatus.failure, error: e.toString())),
    );
  }

  Future<void> _onPlaceRequested(
    OrderPlaceRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _orderRepository.placeOrder(event.order);
    } catch (e) {
      emit(state.copyWith(status: OrderStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onCancelRequested(
    OrderCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _orderRepository.cancelOrder(event.orderId);
    } catch (e) {
      emit(state.copyWith(status: OrderStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onStatusUpdateRequested(
    OrderStatusUpdateRequested event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _orderRepository.updateOrderStatus(event.orderId, event.newStatus);
    } catch (e) {
      emit(state.copyWith(status: OrderStatus.failure, error: e.toString()));
    }
  }

  void _onInternalChanged(
    OrdersInternalChanged event,
    Emitter<OrderState> emit,
  ) {
    emit(state.copyWith(
      status: OrderStatus.success,
      orders: event.orders,
    ));
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }
}
