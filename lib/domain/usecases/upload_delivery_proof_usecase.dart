import 'dart:io';
import '../repositories/delivery_repository.dart';

class UploadDeliveryProofUsecase {
  final DeliveryRepository repository;
  const UploadDeliveryProofUsecase(this.repository);
  Future<void> call({required String orderId, required File image, String? note}) {
    return repository.uploadProof(orderId: orderId, image: image, note: note);
  }
}
