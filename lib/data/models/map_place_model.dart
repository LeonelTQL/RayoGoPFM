import '../../domain/entities/map_place.dart';

class MapPlaceModel extends MapPlace {
  const MapPlaceModel({
    required super.placeId,
    required super.description,
    required super.mainText,
    required super.secondaryText,
    super.name,
    super.formattedAddress,
    super.latitude,
    super.longitude,
  });

  factory MapPlaceModel.fromPredictionJson(Map<String, dynamic> json) {
    return MapPlaceModel(
      placeId: json['placeId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      mainText: json['mainText']?.toString() ?? json['description']?.toString() ?? '',
      secondaryText: json['secondaryText']?.toString() ?? '',
    );
  }

  factory MapPlaceModel.fromDetailsJson(Map<String, dynamic> json) {
    return MapPlaceModel(
      placeId: json['placeId']?.toString() ?? '',
      description: json['formattedAddress']?.toString() ?? json['name']?.toString() ?? '',
      mainText: json['name']?.toString() ?? json['formattedAddress']?.toString() ?? 'Dirección',
      secondaryText: json['formattedAddress']?.toString() ?? '',
      name: json['name']?.toString(),
      formattedAddress: json['formattedAddress']?.toString(),
      latitude: json['latitude'] == null ? null : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null ? null : double.tryParse(json['longitude'].toString()),
    );
  }
}
