import 'package:flutter_test/flutter_test.dart';
import 'package:pry_proyecto_final_delivery/data/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    const productJson = {
      'id': 'prod-123',
      'name': 'Sushi Roll',
      'price': 12.99,
      'stock': 20,
      'active': true,
      'discountPercent': 10,
      'originalPrice': 15.00
    };

    test('should parse from json correctly', () {
      final product = ProductModel.fromJson(productJson);
      expect(product.id, 'prod-123');
      expect(product.name, 'Sushi Roll');
      expect(product.price, 12.99);
      expect(product.stock, 20);
      expect(product.active, true);
      expect(product.discountPercent, 10);
      expect(product.originalPrice, 15.00);
      expect(product.hasDiscount, true);
      expect(product.restaurantDisplayName, 'Smart Delivery Market');
      expect(product.deliveryWindow, '25-45 min');
    });
  });
}
