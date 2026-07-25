import '../../domain/entities/delivery_route.dart';
import '../../domain/entities/map_place.dart';
import '../../domain/repositories/maps_repository.dart';
import '../datasource/remote/maps_remote_datasource.dart';
import '../models/delivery_route_model.dart';
import '../models/map_place_model.dart';

class MapsRepositoryImpl implements MapsRepository {
  final MapsRemoteDatasource datasource;
  MapsRepositoryImpl(this.datasource);

  @override
  Future<List<MapPlace>> autocomplete(String input) async {
    final json = await datasource.autocomplete(input);
    final raw = json['predictions'] as List<dynamic>? ?? [];
    return raw.map((item) => MapPlaceModel.fromPredictionJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<MapPlace?> placeDetails(String placeId) async {
    final json = await datasource.placeDetails(placeId);
    final raw = json['place'];
    if (raw == null) return null;
    return MapPlaceModel.fromDetailsJson(raw as Map<String, dynamic>);
  }

  @override
  Future<MapPlace?> reverseGeocode({required double latitude, required double longitude}) async {
    final json = await datasource.reverseGeocode(latitude: latitude, longitude: longitude);
    final raw = json['result'];
    if (raw == null) return null;
    return MapPlaceModel.fromDetailsJson(raw as Map<String, dynamic>);
  }

  @override
  Future<DeliveryRoute?> route({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  }) async {
    final json = await datasource.route(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      travelMode: travelMode,
    );
    final raw = json['route'];
    if (raw == null) return null;
    return DeliveryRouteModel.fromJson(raw as Map<String, dynamic>);
  }
}
