import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<OrderModel>> getOrders(String uid) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }

  @override
  Stream<List<OrderModel>> watchOrders(String? uid) {
    Query query = _firestore.collection('orders');
    if (uid != null) {
      query = query.where('user_id', isEqualTo: uid);
    }
    return query.snapshots().map((snapshot) {
      final orders = snapshot.docs.map((d) => OrderModel.fromFirestore(d)).toList();
      orders.sort((a, b) {
        final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return orders;
    });
  }

  @override
  Future<void> placeOrder(OrderModel order) async {
    await _firestore.collection('orders').add(order.toFirestore());
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
