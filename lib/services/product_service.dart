import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository _repository;

  ProductService(this._repository);

  Future<List<Product>> getProducts() {
    return _repository.getProducts();
  }

  Future<Product?> getProductBySlug(String slug,) {
    return _repository.getProductBySlug(slug,);
  }

  Future<List<Product>> getRelatedProducts(String categorySlug,) {
    return _repository.getRelatedProducts(categorySlug,);
  }
}