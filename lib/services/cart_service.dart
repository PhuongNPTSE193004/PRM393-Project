import '../models/cart_item.dart';
import '../repositories/cart_repository.dart';

class CartService {
  final CartRepository _repository;

  CartService(this._repository);

  Future<List<CartItem>> getCartItems(
      String uid,
      ) {
    return _repository.getCartItems(uid);
  }
}