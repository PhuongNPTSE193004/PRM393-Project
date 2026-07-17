class Product {
  final String slug;
  final String name;
  final String? brand;
  final double price;
  final double? discountPrice;
  final double rating;
  final int? fps;
  final int stock;
  final String categorySlug;
  final List<String> images;

  final String description;
  final String? material;
  final String? magazine;
  final String? battery;
  final String? powerSource;
  final String? fireMode;
  final double? barrelLength;
  final double? weight;
  final String? warranty;
  final bool isAvailable;
  final DateTime? createdAt;

  Product({
    required this.slug,
    required this.name,
    this.brand,
    required this.price,
    this.discountPrice,
    required this.rating,
    this.fps,
    required this.stock,
    required this.categorySlug,
    this.images = const [],
    this.description = '',
    this.material,
    this.magazine,
    this.battery,
    this.powerSource,
    this.fireMode,
    this.barrelLength,
    this.weight,
    this.warranty,
    this.isAvailable = true,
    this.createdAt,
  });
}
