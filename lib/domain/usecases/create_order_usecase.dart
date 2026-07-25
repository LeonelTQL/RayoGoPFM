import '../entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class CreateOrderUsecase {
  final OrderRepository repository;
  const CreateOrderUsecase(this.repository);
  Future<Order> call({required String deliveryAddressId, required String paymentMethod, String? note, required List<CartItem> items}) {
    return repository.createOrder(deliveryAddressId: deliveryAddressId, paymentMethod: paymentMethod, note: note, items: items);
  }
}
