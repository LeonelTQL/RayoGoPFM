import 'api_client.dart';

class MapsRemoteDatasource {
  final ApiClient apiClient;
  const MapsRemoteDatasource(this.apiClient);

  Future<dynamic> autocomplete(String input) {
    return apiClient.get('/maps/places/autocomplete?input=${Uri.encodeComponent(input)}');
  }

  Future<dynamic> placeDetails(String placeId) {
    return apiClient.get('/maps/places/details/${Uri.encodeComponent(placeId)}');
  }

  Future<dynamic> reverseGeocode({required double latitude, required double longitude}) {
    return apiClient.get('/maps/reverse-geocode?lat=$latitude&lng=$longitude');
  }

  Future<dynamic> route({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  }) {
    return apiClient.post('/maps/route', {
      'origin': {'lat': originLat, 'lng': originLng},
      'destination': {'lat': destinationLat, 'lng': destinationLng},
      'travelMode': travelMode,
    });
  }
}
