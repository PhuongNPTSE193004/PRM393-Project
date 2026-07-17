class Cart {
  final String id;
  final String userId;
  final double totalPrice;
  final DateTime? updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.totalPrice,
    this.updatedAt,
  });
}
