import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasource/remote/api_client.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient apiClient;
  OrderRepositoryImpl(this.apiClient);

  @override
  Future<String> createAddress({required String label, required String addressLine, required double latitude, required double longitude}) async {
    final json = await apiClient.post('/addresses', {
      'label': label,
      'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': true,
    });
    return json['address']['id'].toString();
  }

  @override
  Future<Order> createOrder({required String deliveryAddressId, required String paymentMethod, String? note, required List<CartItem> items}) async {
    final json = await apiClient.post('/orders', {
      'deliveryAddressId': deliveryAddressId,
      'paymentMethod': paymentMethod,
      'note': note,
      'items': items.map((item) => {'productId': item.product.id, 'quantity': item.quantity}).toList(),
    });
    return OrderModel.fromJson(json['order'] as Map<String, dynamic>);
  }

  @override
  Future<List<Order>> myOrders() async {
    final json = await apiClient.get('/orders/my-orders');
    return (json['orders'] as List<dynamic>).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Order>> adminOrders() async {
    final json = await apiClient.get('/orders/admin/all');
    return (json['orders'] as List<dynamic>).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Order>> deliveryOrders() async {
    final json = await apiClient.get('/delivery/orders');
    return (json['orders'] as List<dynamic>).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Order> getOrder(String id) async {
    final json = await apiClient.get('/orders/$id');
    return OrderModel.fromJson(json['order'] as Map<String, dynamic>);
  }

  @override
  Future<Order> updateStatus(String id, String status) async {
    final json = await apiClient.patch('/orders/$id/status', {'status': status});
    return OrderModel.fromJson(json['order'] as Map<String, dynamic>);
  }

  @override
  Future<Order> assignRider(String orderId, String riderId) async {
    final json = await apiClient.patch('/orders/$orderId/assign', {'riderId': riderId});
    return OrderModel.fromJson(json['order'] as Map<String, dynamic>);
  }

  @override
  Future<Order> acceptOrder(String orderId) async {
    final json = await apiClient.patch('/orders/$orderId/accept', {});
    return OrderModel.fromJson(json['order'] as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> riders() async {
    final json = await apiClient.get('/orders/riders');
    return (json['riders'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
  }
}
