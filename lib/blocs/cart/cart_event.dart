import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartLoadRequested extends CartEvent {
  final String uid;
  const CartLoadRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}

class CartItemAdded extends CartEvent {
  final String uid;
  final String productSlug;
  final int quantity;

  const CartItemAdded({
    required this.uid,
    required this.productSlug,
    required this.quantity,
  });

  @override
  List<Object?> get props => [uid, productSlug, quantity];
}

class CartItemQuantityUpdated extends CartEvent {
  final String uid;
  final String productSlug;
  final int quantity;

  const CartItemQuantityUpdated({
    required this.uid,
    required this.productSlug,
    required this.quantity,
  });

  @override
  List<Object?> get props => [uid, productSlug, quantity];
}

class CartItemRemoved extends CartEvent {
  final String uid;
  final String productSlug;

  const CartItemRemoved({
    required this.uid,
    required this.productSlug,
  });

  @override
  List<Object?> get props => [uid, productSlug];
}
