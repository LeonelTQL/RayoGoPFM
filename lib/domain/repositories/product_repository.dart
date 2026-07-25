import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? search});
  Future<Product> createProduct({String? categoryId, required String name, String? description, required double price, required int stock, String? imageUrl});
}
