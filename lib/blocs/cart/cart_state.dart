import 'package:equatable/equatable.dart';
import '../../models/cart_item.dart';

enum CartStatus { initial, loading, success, failure }

class CartState extends Equatable {
  final CartStatus status;
  final List<CartItem> items;
  final String? error;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, items, error];

  double get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    CartStatus? status,
    List<CartItem>? items,
    String? error,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }
}
