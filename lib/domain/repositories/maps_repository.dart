import '../entities/map_place.dart';
import '../entities/delivery_route.dart';

abstract class MapsRepository {
  Future<List<MapPlace>> autocomplete(String input);
  Future<MapPlace?> placeDetails(String placeId);
  Future<MapPlace?> reverseGeocode({required double latitude, required double longitude});
  Future<DeliveryRoute?> route({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  });
}
