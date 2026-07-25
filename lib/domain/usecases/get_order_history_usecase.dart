import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrderHistoryUsecase {
  final OrderRepository repository;
  const GetOrderHistoryUsecase(this.repository);
  Future<List<Order>> call() => repository.myOrders();
}
