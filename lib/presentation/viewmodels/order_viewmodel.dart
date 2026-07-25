import 'package:flutter/material.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepository repository;
  OrderViewModel(this.repository);

  List<Order> orders = [];
  Order? selectedOrder;
  List<Map<String, dynamic>> riders = [];
  bool loading = false;
  String? error;

  Future<bool> createOrder({required String addressLine, required double latitude, required double longitude, required String paymentMethod, String? note, required List<CartItem> items}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final addressId = await repository.createAddress(label: 'Entrega', addressLine: addressLine, latitude: latitude, longitude: longitude);
      selectedOrder = await repository.createOrder(deliveryAddressId: addressId, paymentMethod: paymentMethod, note: note, items: items);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> createOrderWithAddressId({required String deliveryAddressId, required String paymentMethod, String? note, required List<CartItem> items}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      selectedOrder = await repository.createOrder(deliveryAddressId: deliveryAddressId, paymentMethod: paymentMethod, note: note, items: items);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyOrders() async => _load(() => repository.myOrders());
  Future<void> loadAdminOrders() async => _load(() => repository.adminOrders());
  Future<void> loadDeliveryOrders() async => _load(() => repository.deliveryOrders());

  Future<void> loadRiders() async {
    try {
      riders = await repository.riders();
      notifyListeners();
    } catch (_) {}
  }

  Future<Order?> loadOrder(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      selectedOrder = await repository.getOrder(id);
      loading = false;
      notifyListeners();
      return selectedOrder;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final updated = await repository.updateStatus(id, status);
    final index = orders.indexWhere((order) => order.id == id);
    if (index >= 0) orders[index] = updated;
    selectedOrder = updated;
    notifyListeners();
  }

  Future<void> assignRider(String orderId, String riderId) async {
    await repository.assignRider(orderId, riderId);
    await loadAdminOrders();
  }

  Future<bool> acceptOrder(String orderId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final updated = await repository.acceptOrder(orderId);
      selectedOrder = updated;
      
      // Actualizar la lista local de pedidos disponibles
      orders.removeWhere((o) => o.id == orderId);
      
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _load(Future<List<Order>> Function() loader) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      orders = await loader();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
