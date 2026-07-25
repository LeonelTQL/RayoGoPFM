import '../../domain/entities/delivery_route.dart';

class DeliveryRouteModel extends DeliveryRoute {
  const DeliveryRouteModel({
    required super.distanceMeters,
    super.duration,
    super.encodedPolyline,
    super.points = const [],
  });

  factory DeliveryRouteModel.fromJson(Map<String, dynamic> json) {
    final encoded = json['encodedPolyline']?.toString();
    return DeliveryRouteModel(
      distanceMeters: int.tryParse(json['distanceMeters'].toString()) ?? 0,
      duration: json['duration']?.toString(),
      encodedPolyline: encoded,
      points: encoded == null || encoded.isEmpty ? const [] : _decodePolyline(encoded),
    );
  }

  static List<MapPoint> _decodePolyline(String encoded) {
    final points = <MapPoint>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(MapPoint(latitude: lat / 1E5, longitude: lng / 1E5));
    }

    return points;
  }
}
