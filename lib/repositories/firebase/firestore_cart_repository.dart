import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../cart_repository.dart';
import '../product_repository.dart';

/// Firestore implementation of [CartRepository].
///
/// Schema:
/// ```
/// users/{uid}/cart/{productSlug}
///   productSlug: string
///   quantity: number
///   addedAt: timestamp
///   updatedAt: timestamp
/// ```
///
/// Only `productSlug` and `quantity` are persisted per cart line — product
/// details (price, name, images, stock) are resolved on read via
/// [ProductRepository] so the cart always reflects current product data
/// instead of a stale snapshot.
class FirestoreCartRepository implements CartRepository {
  final FirebaseFirestore _firestore;
  final ProductRepository _productRepository;

  FirestoreCartRepository(
    this._productRepository, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  @override
  Future<List<CartItem>> getCartItems(String uid) async {
    final snapshot = await _cartCollection(uid).get();

    final items = <CartItem>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productSlug = data['productSlug'] as String? ?? doc.id;
      final quantity = (data['quantity'] as num?)?.toInt() ?? 0;

      final product = await _productRepository.getProductBySlug(productSlug);

      // Skip cart lines whose product no longer exists (e.g. delisted item)
      // rather than throwing, so a single bad row doesn't break the cart.
      if (product == null) continue;

      items.add(CartItem(product: product, quantity: quantity));
    }

    return items;
  }

  @override
  Future<void> addToCart({
    required String uid,
    required String productSlug,
    required int quantity,
  }) async {
    final docRef = _cartCollection(uid).doc(productSlug);
    final existing = await docRef.get();

    if (existing.exists) {
      final currentQuantity =
          (existing.data()?['quantity'] as num?)?.toInt() ?? 0;

      await docRef.update({
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'productSlug': productSlug,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> updateQuantity({
    required String uid,
    required String productSlug,
    required int quantity,
  }) {
    return _cartCollection(uid).doc(productSlug).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeItem({required String uid, required String productSlug}) {
    return _cartCollection(uid).doc(productSlug).delete();
  }
}
