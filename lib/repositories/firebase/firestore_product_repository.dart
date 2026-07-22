import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_repository.dart';
import '../../models/product.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Product _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromData(doc.id, doc.data());
  }

  Product _fromData(String docId, Map<String, dynamic> data) {
    final createdAtVal = data['createdAt'];
    return Product(
      slug: data['slug'] ?? docId,
      name: data['name'] ?? data['title'] ?? 'Unknown',
      brand: data['brand'],
      price: (data['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      fps: data['fps'] as int?,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      categorySlug: data['categorySlug'] ?? '',
      description: data['description'] ?? '',
      material: data['material'],
      magazine: data['magazine'],
      battery: data['battery'],
      powerSource: data['powerSource'],
      fireMode: data['fireMode'],
      barrelLength: (data['barrelLength'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      warranty: data['warranty'],
      isAvailable: data['isAvailable'] as bool? ?? true,
      createdAt: createdAtVal is Timestamp ? createdAtVal.toDate() : null,
      images: List<String>.from(data['images'] ?? []),
    );
  }

  @override
  Future<List<Product>> getProducts() async {
    final snapshot = await _products.get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Stream<List<Product>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromData(doc.id, doc.data())).toList();
    });
  }

  @override
  Future<Product?> getProductBySlug(String slug) async {
    final doc = await _products.doc(slug).get();
    if (!doc.exists) return null;
    return _fromData(doc.id, doc.data()!);
  }

  @override
  Future<List<Product>> getRelatedProducts(String categorySlug) async {
    final snapshot = await _products
        .where('categorySlug', isEqualTo: categorySlug)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  @override
  Future<void> deleteProduct(String slug) async {
    await _products.doc(slug).delete();
  }
}
