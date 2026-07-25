import '../entities/cart_item.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<String> createAddress({required String label, required String addressLine, required double latitude, required double longitude});
  Future<Order> createOrder({required String deliveryAddressId, required String paymentMethod, String? note, required List<CartItem> items});
  Future<List<Order>> myOrders();
  Future<List<Order>> adminOrders();
  Future<List<Order>> deliveryOrders();
  Future<Order> getOrder(String id);
  Future<Order> updateStatus(String id, String status);
  Future<Order> assignRider(String orderId, String riderId);
  Future<Order> acceptOrder(String orderId);
  Future<List<Map<String, dynamic>>> riders();
}
