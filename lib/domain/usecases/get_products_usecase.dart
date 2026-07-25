import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUsecase {
  final ProductRepository repository;
  const GetProductsUsecase(this.repository);
  Future<List<Product>> call({String? search}) => repository.getProducts(search: search);
}
