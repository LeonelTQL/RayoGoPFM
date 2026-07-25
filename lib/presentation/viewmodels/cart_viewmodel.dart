import 'package:flutter/material.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get deliveryFee => _items.isEmpty ? 0 : (_items.first.product.deliveryFee);
  double get serviceFee => _items.isEmpty ? 0 : (_items.first.product.serviceFee);
  double get total => _items.isEmpty ? 0 : subtotal + deliveryFee + serviceFee;
  double get minOrderAmount => _items.isEmpty ? 0 : _items.first.product.minOrderAmount;
  double get missingToMinOrder => subtotal >= minOrderAmount ? 0 : minOrderAmount - subtotal;
  bool get canCheckout => _items.isNotEmpty && subtotal >= minOrderAmount;
  String? get restaurantId => _items.isEmpty ? null : _items.first.product.restaurantId;
  String get restaurantName => _items.isEmpty ? 'Tu carrito' : _items.first.product.restaurantDisplayName;
  double get commissionRate => _items.isEmpty ? 0 : _items.first.product.commissionRate;
  double get estimatedRestaurantCommission => subtotal * commissionRate;
  double get estimatedRestaurantPayout => subtotal - estimatedRestaurantCommission;

  bool canAccept(Product product) {
    if (_items.isEmpty) return true;
    return restaurantId == product.restaurantId || product.restaurantId == null || restaurantId == null;
  }

  bool add(Product product) {
    if (!canAccept(product)) return false;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final current = _items[index];
      if (current.quantity < product.stock) {
        _items[index] = current.copyWith(quantity: current.quantity + 1);
      }
    } else if (product.stock > 0) {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
    return true;
  }

  void remove(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  bool increment(Product product) => add(product);

  void decrement(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) return;
    final current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
