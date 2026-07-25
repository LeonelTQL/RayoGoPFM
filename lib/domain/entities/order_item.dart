class OrderItem {
  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  const OrderItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}
