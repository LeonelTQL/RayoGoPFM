import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasource/remote/api_client.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient apiClient;
  ProductRepositoryImpl(this.apiClient);

  @override
  Future<List<Product>> getProducts({String? search}) async {
    final path = search == null || search.isEmpty ? '/products' : '/products?search=${Uri.encodeQueryComponent(search)}';
    final json = await apiClient.get(path);
    final raw = json['products'] as List<dynamic>;
    return raw.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Product> createProduct({String? categoryId, required String name, String? description, required double price, required int stock, String? imageUrl}) async {
    final json = await apiClient.post('/products', {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    });
    return ProductModel.fromJson(json['product'] as Map<String, dynamic>);
  }
}
