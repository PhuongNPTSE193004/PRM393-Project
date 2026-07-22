import '../models/order.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders(String uid);
  Stream<List<OrderModel>> watchOrders(String? uid);
  Future<void> placeOrder(OrderModel order);
  Future<void> cancelOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, String newStatus);
}
