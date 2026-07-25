import '../../domain/entities/cart_item.dart';
import 'product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({required super.product, required super.quantity});

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
    );
  }
}
