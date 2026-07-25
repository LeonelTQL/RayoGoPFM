import 'order_item.dart';

class Order {
  final String id;
  final String? customerName;
  final String? riderId;
  final String? riderName;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? note;
  final String? createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    this.customerName,
    this.riderId,
    this.riderName,
    this.addressLine,
    this.latitude,
    this.longitude,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.note,
    this.createdAt,
    this.items = const [],
  });
}
