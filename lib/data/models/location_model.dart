import '../../domain/entities/delivery_location.dart';

class LocationModel extends DeliveryLocation {
  const LocationModel({
    required super.orderId,
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
      accuracy: json['accuracy'] == null ? null : double.tryParse(json['accuracy'].toString()),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }
}
