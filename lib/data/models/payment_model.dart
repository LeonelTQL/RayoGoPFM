import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.method,
    required super.status,
    required super.amount,
    super.proofImageUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      method: json['method']?.toString() ?? 'efectivo',
      status: json['status']?.toString() ?? 'pendiente',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      proofImageUrl: json['proofImageUrl']?.toString() ?? json['proof_image_url']?.toString(),
    );
  }
}
