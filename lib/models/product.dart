class Category {
  final String slug;
  final String nameVi;

  Category({required this.slug, required this.nameVi});
}

class Product {
  final String slug;
  final String name;
  final double price;
  final double rating;
  final int? fps;
  final int stock;
  final String categorySlug;
  final List<String> images;

  Product({
    required this.slug,
    required this.name,
    required this.price,
    required this.rating,
    this.fps,
    required this.stock,
    required this.categorySlug,
    this.images = const [],
  });
}
