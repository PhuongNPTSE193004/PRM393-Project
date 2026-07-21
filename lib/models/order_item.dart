import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderItemModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? 'Unknown Product',
      unitPrice: (data['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
