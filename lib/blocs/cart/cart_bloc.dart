import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc({required CartRepository cartRepository})
      : _cartRepository = cartRepository,
        super(const CartState()) {
    on<CartLoadRequested>(_onLoadRequested);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemQuantityUpdated>(_onItemQuantityUpdated);
    on<CartItemRemoved>(_onItemRemoved);
  }

  Future<void> _onLoadRequested(
    CartLoadRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final items = await _cartRepository.getCartItems(event.uid);
      emit(state.copyWith(
        status: CartStatus.success,
        items: items,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _cartRepository.addToCart(
        uid: event.uid,
        productSlug: event.productSlug,
        quantity: event.quantity,
      );
      add(CartLoadRequested(event.uid));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _cartRepository.updateQuantity(
        uid: event.uid,
        productSlug: event.productSlug,
        quantity: event.quantity,
      );
      add(CartLoadRequested(event.uid));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    try {
      await _cartRepository.removeItem(
        uid: event.uid,
        productSlug: event.productSlug,
      );
      add(CartLoadRequested(event.uid));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
