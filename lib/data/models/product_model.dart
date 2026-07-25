import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    super.categoryId,
    super.categoryName,
    super.restaurantId,
    super.restaurantName,
    super.restaurantLogoUrl,
    super.restaurantCoverUrl,
    super.restaurantRating,
    super.ratingCount,
    super.deliveryMinutesMin,
    super.deliveryMinutesMax,
    super.deliveryFee,
    super.serviceFee,
    super.commissionRate,
    super.minOrderAmount,
    required super.name,
    super.description,
    required super.price,
    super.originalPrice,
    super.discountPercent,
    required super.stock,
    super.imageUrl,
    required super.active,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value, [double fallback = 0]) => double.tryParse(value?.toString() ?? '') ?? fallback;
    int asInt(dynamic value, [int fallback = 0]) => int.tryParse(value?.toString() ?? '') ?? fallback;
    return ProductModel(
      id: json['id'].toString(),
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      categoryName: json['categoryName']?.toString() ?? json['category_name']?.toString(),
      restaurantId: json['restaurantId']?.toString() ?? json['restaurant_id']?.toString(),
      restaurantName: json['restaurantName']?.toString() ?? json['restaurant_name']?.toString(),
      restaurantLogoUrl: json['restaurantLogoUrl']?.toString() ?? json['restaurant_logo_url']?.toString(),
      restaurantCoverUrl: json['restaurantCoverUrl']?.toString() ?? json['restaurant_cover_url']?.toString(),
      restaurantRating: asDouble(json['restaurantRating'] ?? json['restaurant_rating'], 4.6),
      ratingCount: asInt(json['ratingCount'] ?? json['rating_count'], 120),
      deliveryMinutesMin: asInt(json['deliveryMinutesMin'] ?? json['delivery_minutes_min'], 25),
      deliveryMinutesMax: asInt(json['deliveryMinutesMax'] ?? json['delivery_minutes_max'], 45),
      deliveryFee: asDouble(json['deliveryFee'] ?? json['delivery_fee'], 1.50),
      serviceFee: asDouble(json['serviceFee'] ?? json['service_fee'], 0.35),
      commissionRate: asDouble(json['commissionRate'] ?? json['commission_rate'], 0.18),
      minOrderAmount: asDouble(json['minOrderAmount'] ?? json['min_order_amount'], 5.00),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: asDouble(json['price']),
      originalPrice: json['originalPrice'] == null && json['original_price'] == null ? null : asDouble(json['originalPrice'] ?? json['original_price']),
      discountPercent: asInt(json['discountPercent'] ?? json['discount_percent'], 0),
      stock: asInt(json['stock']),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      active: json['active'] == true || json['active'] == null,
    );
  }
}
