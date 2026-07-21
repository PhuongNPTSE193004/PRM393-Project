import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final double total;
  final String status;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String shippingCity;
  final String paymentMethod;
  final String notes;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
    required this.shippingCity,
    required this.paymentMethod,
    this.notes = '',
    this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    if (data['created_at'] is Timestamp) {
      created = (data['created_at'] as Timestamp).toDate();
    }

    return OrderModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'pending',
      shippingName: data['shipping_name'] ?? '',
      shippingPhone: data['shipping_phone'] ?? '',
      shippingAddress: data['shipping_address'] ?? '',
      shippingCity: data['shipping_city'] ?? '',
      paymentMethod: data['payment_method'] ?? 'cod',
      notes: data['notes'] ?? '',
      createdAt: created,
    );
  }
}
