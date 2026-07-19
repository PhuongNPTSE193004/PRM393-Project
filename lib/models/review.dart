class Review {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });
}
