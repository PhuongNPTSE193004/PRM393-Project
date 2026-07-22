import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductLoadRequested extends ProductEvent {}

class ProductSubscriptionRequested extends ProductEvent {}

class ProductDeleteRequested extends ProductEvent {
  final String slug;
  const ProductDeleteRequested(this.slug);

  @override
  List<Object?> get props => [slug];
}

class ProductsInternalChanged extends ProductEvent {
  final List<Product> products;
  const ProductsInternalChanged(this.products);

  @override
  List<Object?> get props => [products];
}
