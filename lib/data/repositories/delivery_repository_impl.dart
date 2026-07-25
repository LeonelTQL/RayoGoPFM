import 'dart:io';
import '../../domain/entities/delivery_location.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasource/remote/api_client.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final ApiClient apiClient;
  DeliveryRepositoryImpl(this.apiClient);

  @override
  Future<void> sendLocation({required String orderId, required double latitude, required double longitude, double? accuracy}) async {
    await apiClient.post('/delivery/location', {
      'orderId': orderId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    });
  }

  @override
  Future<DeliveryLocation?> latestLocation(String orderId) async {
    final json = await apiClient.get('/delivery/location/$orderId');
    final raw = json['location'];
    if (raw == null) return null;
    return DeliveryLocation(
      orderId: raw['order_id'].toString(),
      latitude: double.tryParse(raw['latitude'].toString()) ?? 0,
      longitude: double.tryParse(raw['longitude'].toString()) ?? 0,
      accuracy: raw['accuracy'] == null ? null : double.tryParse(raw['accuracy'].toString()),
      createdAt: raw['created_at']?.toString(),
    );
  }

  @override
  Future<void> uploadProof({required String orderId, required File image, String? note}) async {
    await apiClient.uploadImage('/delivery/proof', image, fields: {'orderId': orderId, if (note != null) 'note': note});
  }
}
