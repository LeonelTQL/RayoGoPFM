import '../repositories/delivery_repository.dart';

class UpdateDeliveryLocationUsecase {
  final DeliveryRepository repository;
  const UpdateDeliveryLocationUsecase(this.repository);
  Future<void> call({required String orderId, required double latitude, required double longitude, double? accuracy}) {
    return repository.sendLocation(orderId: orderId, latitude: latitude, longitude: longitude, accuracy: accuracy);
  }
}
