class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final String orderStatus;
  final double shippingFee;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    this.orderStatus = 'pending',
    this.shippingFee = 0,
    this.createdAt,
  });
}
