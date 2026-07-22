import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;
  StreamSubscription? _productSubscription;

  ProductBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const ProductState()) {
    on<ProductLoadRequested>(_onLoadRequested);
    on<ProductSubscriptionRequested>(_onSubscriptionRequested);
    on<ProductDeleteRequested>(_onDeleteRequested);
    on<ProductsInternalChanged>(_onInternalChanged);
  }

  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));
    try {
      final products = await _productRepository.getProducts();
      emit(state.copyWith(
        status: ProductStatus.success,
        products: products,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSubscriptionRequested(
    ProductSubscriptionRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));
    await _productSubscription?.cancel();
    _productSubscription = _productRepository.watchProducts().listen(
      (products) => add(ProductsInternalChanged(products)),
      onError: (e) => emit(state.copyWith(status: ProductStatus.failure, error: e.toString())),
    );
  }

  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await _productRepository.deleteProduct(event.slug);
    } catch (e) {
      emit(state.copyWith(status: ProductStatus.failure, error: e.toString()));
    }
  }

  void _onInternalChanged(
    ProductsInternalChanged event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      status: ProductStatus.success,
      products: event.products,
    ));
  }

  @override
  Future<void> close() {
    _productSubscription?.cancel();
    return super.close();
  }
}
