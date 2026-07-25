import 'dart:io';
import '../entities/delivery_location.dart';

abstract class DeliveryRepository {
  Future<void> sendLocation({required String orderId, required double latitude, required double longitude, double? accuracy});
  Future<DeliveryLocation?> latestLocation(String orderId);
  Future<void> uploadProof({required String orderId, required File image, String? note});
}
