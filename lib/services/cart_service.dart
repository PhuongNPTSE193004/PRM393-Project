import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';

/// Business logic for the shopping cart.
///
/// Screens must call this service instead of [CartRepository] directly,
/// per the project dependency rule (screens/ -> services/ -> repositories/).
class CartService {
  final CartRepository _repository;

  CartService(this._repository);

  Future<List<CartItem>> getCartItems(String uid) {
    return _repository.getCartItems(uid);
  }

  /// Adds [quantity] units of the product identified by [productSlug] to the
  /// cart. Throws [ArgumentError] if [quantity] is not positive — this is a
  /// business rule and therefore belongs in the service layer, not the UI.
  Future<void> addToCart({
    required String uid,
    required String productSlug,
    required int quantity,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Must be greater than zero',
      );
    }

    return _repository.addToCart(
      uid: uid,
      productSlug: productSlug,
      quantity: quantity,
    );
  }

  /// Updates the quantity of an existing cart line.
  ///
  /// A [quantity] of zero or less removes the item, mirroring the common
  /// "decrement to remove" UX in the cart screen.
  Future<void> updateQuantity({
    required String uid,
    required String productSlug,
    required int quantity,
  }) {
    if (quantity <= 0) {
      return _repository.removeItem(uid: uid, productSlug: productSlug);
    }

    return _repository.updateQuantity(
      uid: uid,
      productSlug: productSlug,
      quantity: quantity,
    );
  }

  Future<void> removeItem({required String uid, required String productSlug}) {
    return _repository.removeItem(uid: uid, productSlug: productSlug);
  }

  /// Sum of (unit price * quantity) across all cart items.
  double calculateSubtotal(List<CartItem> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  /// Total item count across all cart lines (used for badge counts, etc).
  int calculateItemCount(List<CartItem> items) {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}
