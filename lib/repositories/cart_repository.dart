import '../models/cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems(
      String uid,
      );

  Future<void> addToCart({
    required String uid,
    required String productSlug,
    required int quantity,
  });

  Future<void> updateQuantity({
    required String uid,
    required String productSlug,
    required int quantity,
  });

  Future<void> removeItem({
    required String uid,
    required String productSlug,
  });
}