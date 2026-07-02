import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_repository.dart';
import '../../models/product.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  @override
  Future<List<Product>> getProducts() async {
    final snapshot = await _products.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Product(
        slug: data['slug'] ?? doc.id,
        name: data['name'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        fps: data['fps'],
        stock: data['stock'] ?? 0,
        categorySlug: data['categorySlug'] ?? '',
        description: data['description'] ?? '',
        material: data['material'],
        magazine: data['magazine'],
        battery: data['battery'],
        images: List<String>.from(data['images'] ?? []),
      );
    }).toList();
  }

  @override
  Future<Product?> getProductBySlug(String slug) async {
    final doc = await _products.doc(slug).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;

    return Product(
      slug: data['slug'] ?? doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      fps: data['fps'],
      stock: data['stock'] ?? 0,
      categorySlug: data['categorySlug'] ?? '',
      description: data['description'] ?? '',
      material: data['material'],
      magazine: data['magazine'],
      battery: data['battery'],
      images: List<String>.from(data['images'] ?? []),
    );
  }

  @override
  Future<List<Product>> getRelatedProducts(String categorySlug) async {
    final snapshot = await _products
        .where('categorySlug', isEqualTo: categorySlug)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Product(
        slug: data['slug'] ?? doc.id,
        name: data['name'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        fps: data['fps'],
        stock: data['stock'] ?? 0,
        categorySlug: data['categorySlug'] ?? '',
        description: data['description'] ?? '',
        material: data['material'],
        magazine: data['magazine'],
        battery: data['battery'],
        images: List<String>.from(data['images'] ?? []),
      );
    }).toList();
  }
}
