import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Stream<List<Product>> watchProducts();
  Future<Product?> getProductBySlug(String slug);
  Future<List<Product>> getRelatedProducts(String categorySlug);
  Future<void> deleteProduct(String slug);
}
