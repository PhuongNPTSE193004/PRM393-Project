import 'package:cloud_firestore/cloud_firestore.dart';
import '../category_repository.dart';
import '../../models/category.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _categories.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Category(
        id: doc.id,
        name: data['categoryName'] ?? '',
        description: data['description'] ?? '',
      );
    }).toList();
  }
}
