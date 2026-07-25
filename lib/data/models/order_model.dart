import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    super.customerName,
    super.riderId,
    super.riderName,
    super.addressLine,
    super.latitude,
    super.longitude,
    required super.status,
    required super.subtotal,
    required super.deliveryFee,
    required super.total,
    required super.paymentMethod,
    required super.paymentStatus,
    super.note,
    super.createdAt,
    super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return OrderModel(
      id: json['id'].toString(),
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString(),
      riderId: json['riderId']?.toString() ?? json['rider_id']?.toString(),
      riderName: json['riderName']?.toString() ?? json['rider_name']?.toString(),
      addressLine: json['addressLine']?.toString() ?? json['address_line']?.toString(),
      latitude: json['latitude'] == null ? null : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null ? null : double.tryParse(json['longitude'].toString()),
      status: json['status']?.toString() ?? 'pendiente',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      deliveryFee: double.tryParse((json['deliveryFee'] ?? json['delivery_fee'] ?? 0).toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString() ?? 'efectivo',
      paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString() ?? 'pendiente',
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      items: rawItems is List ? rawItems.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList() : const [],
    );
  }
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    super.productId,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'].toString(),
      productId: json['productId']?.toString() ?? json['product_id']?.toString(),
      productName: json['productName']?.toString() ?? json['product_name']?.toString() ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: double.tryParse((json['unitPrice'] ?? json['unit_price'] ?? 0).toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
    );
  }
}
