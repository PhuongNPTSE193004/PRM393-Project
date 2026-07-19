class StoreLocation {
  final String id;
  final String storeName;
  final String address;
  final double latitude;
  final double longitude;
  final String hotline;
  final String openingHours;

  StoreLocation({
    required this.id,
    required this.storeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.hotline = '',
    this.openingHours = '',
  });
}
