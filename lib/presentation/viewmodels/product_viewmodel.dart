import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepository repository;
  ProductViewModel(this.repository);

  List<Product> products = [];

  List<String> get categories {
    final values = products
        .map((product) => product.categoryName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  List<Product> get discountedProducts => products.where((product) => product.hasDiscount).toList();

  List<Product> get popularProducts => products.take(8).toList();
  bool loading = false;
  String? error;

  Future<void> loadProducts({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repository.getProducts(search: search);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> createProduct({String? categoryId, required String name, String? description, required double price, required int stock, String? imageUrl}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.createProduct(categoryId: categoryId, name: name, description: description, price: price, stock: stock, imageUrl: imageUrl);
      await loadProducts();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
