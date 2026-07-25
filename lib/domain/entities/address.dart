class Address {
  final String id;
  final String label;
  final String addressLine;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });
}
