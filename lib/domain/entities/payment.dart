class Payment {
  final String id;
  final String orderId;
  final String method;
  final String status;
  final double amount;
  final String? proofImageUrl;

  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.amount,
    this.proofImageUrl,
  });
}
