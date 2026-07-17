import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repository;

  CategoryService(this._repository);

  Future<List<Category>> getCategories() {
    return _repository.getCategories();
  }
}
