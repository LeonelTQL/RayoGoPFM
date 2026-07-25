import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/delivery_location.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliveryViewModel extends ChangeNotifier {
  final DeliveryRepository repository;
  DeliveryViewModel(this.repository);

  DeliveryLocation? latest;
  bool loading = false;
  String? error;

  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      error = 'Activa el GPS del dispositivo.';
      notifyListeners();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      error = 'Permiso de ubicación denegado.';
      notifyListeners();
      return null;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> sendCurrentLocation(String orderId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        loading = false;
        notifyListeners();
        return false;
      }
      await repository.sendLocation(orderId: orderId, latitude: position.latitude, longitude: position.longitude, accuracy: position.accuracy);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLatestLocation(String orderId) async {
    try {
      latest = await repository.latestLocation(orderId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> uploadProof({required String orderId, required File image, String? note}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.uploadProof(orderId: orderId, image: image, note: note);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
