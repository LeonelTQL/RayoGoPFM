import 'package:flutter/material.dart';
import '../../domain/entities/delivery_route.dart';
import '../../domain/entities/map_place.dart';
import '../../domain/repositories/maps_repository.dart';

class MapsViewModel extends ChangeNotifier {
  final MapsRepository repository;
  MapsViewModel(this.repository);

  List<MapPlace> predictions = [];
  MapPlace? selectedPlace;
  DeliveryRoute? activeRoute;
  bool loading = false;
  String? error;

  Future<void> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 2) {
      predictions = [];
      error = null;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      predictions = await repository.autocomplete(query);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<MapPlace?> selectPrediction(MapPlace place) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      selectedPlace = await repository.placeDetails(place.placeId);
      predictions = [];
      loading = false;
      notifyListeners();
      return selectedPlace;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<MapPlace?> reverseGeocode({required double latitude, required double longitude}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      selectedPlace = await repository.reverseGeocode(latitude: latitude, longitude: longitude);
      loading = false;
      notifyListeners();
      return selectedPlace;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<DeliveryRoute?> loadRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  }) async {
    error = null;
    try {
      activeRoute = await repository.route(
        originLat: originLat,
        originLng: originLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        travelMode: travelMode,
      );
      notifyListeners();
      return activeRoute;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearRoute() {
    activeRoute = null;
    notifyListeners();
  }
}
