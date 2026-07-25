class MapPlace {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final String? name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  const MapPlace({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
