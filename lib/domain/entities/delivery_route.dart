class MapPoint {
  final double latitude;
  final double longitude;

  const MapPoint({required this.latitude, required this.longitude});
}

class DeliveryRoute {
  final int distanceMeters;
  final String? duration;
  final String? encodedPolyline;
  final List<MapPoint> points;

  const DeliveryRoute({
    required this.distanceMeters,
    this.duration,
    this.encodedPolyline,
    this.points = const [],
  });

  double get distanceKm => distanceMeters / 1000;

  String get distanceLabel {
    if (distanceMeters <= 0) return 'Distancia no disponible';
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    if (duration == null || duration!.isEmpty) return 'Tiempo no disponible';
    final seconds = int.tryParse(duration!.replaceAll('s', ''));
    if (seconds == null) return duration!;
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours h' : '$hours h $remaining min';
  }
}
