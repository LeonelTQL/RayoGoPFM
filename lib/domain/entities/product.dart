class Product {
  final String id;
  final String? categoryId;
  final String? categoryName;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantLogoUrl;
  final String? restaurantCoverUrl;
  final double restaurantRating;
  final int ratingCount;
  final int deliveryMinutesMin;
  final int deliveryMinutesMax;
  final double deliveryFee;
  final double serviceFee;
  final double commissionRate;
  final double minOrderAmount;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int discountPercent;
  final int stock;
  final String? imageUrl;
  final bool active;

  const Product({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.restaurantId,
    this.restaurantName,
    this.restaurantLogoUrl,
    this.restaurantCoverUrl,
    this.restaurantRating = 4.6,
    this.ratingCount = 120,
    this.deliveryMinutesMin = 25,
    this.deliveryMinutesMax = 45,
    this.deliveryFee = 1.50,
    this.serviceFee = 0.35,
    this.commissionRate = 0.18,
    this.minOrderAmount = 5.00,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.discountPercent = 0,
    required this.stock,
    this.imageUrl,
    required this.active,
  });

  bool get hasDiscount => discountPercent > 0 || (originalPrice != null && originalPrice! > price);
  String get restaurantDisplayName => restaurantName ?? 'Smart Delivery Market';
  String get deliveryWindow => '$deliveryMinutesMin-$deliveryMinutesMax min';
}
