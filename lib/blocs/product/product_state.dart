import 'package:equatable/equatable.dart';
import '../../models/product.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;
  final String? error;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, products, error];

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    String? error,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error ?? this.error,
    );
  }
}
