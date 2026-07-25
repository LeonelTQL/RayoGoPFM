class DeliveryLocation {
  final String orderId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? createdAt;

  const DeliveryLocation({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.createdAt,
  });
}
