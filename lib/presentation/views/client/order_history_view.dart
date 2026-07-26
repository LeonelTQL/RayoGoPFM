import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/order_status_badge.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrderViewModel>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos'), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.cart), icon: const Icon(Icons.shopping_cart_outlined))]),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.orders.isEmpty
              ? _EmptyOrders(onStart: () => Navigator.pushReplacementNamed(context, AppRoutes.home))
              : RefreshIndicator(
                  onRefresh: () => vm.loadMyOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: vm.orders.length,
                    itemBuilder: (_, index) {
                      final order = vm.orders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: EsquemaColor.card, borderRadius: BorderRadius.circular(22)),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.tracking, arguments: order.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Pedido #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: EsquemaColor.textPrimary))),
                                  OrderStatusBadge(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(order.addressLine ?? 'Sin dirección', style: const TextStyle(color: EsquemaColor.textSecondary)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.payments_outlined, size: 18, color: EsquemaColor.muted),
                                  Text(' ${order.paymentMethod} · ${order.paymentStatus}', style: const TextStyle(color: EsquemaColor.textSecondary)),
                                  const Spacer(),
                                  Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: EsquemaColor.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyOrders({required this.onStart});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 86, color: EsquemaColor.muted),
            const SizedBox(height: 18),
            const Text('Aún no realizaste pedidos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: EsquemaColor.dark)),
            const SizedBox(height: 10),
            const Text('Busca entre todas nuestras opciones y disfruta de tu primer pedido.', textAlign: TextAlign.center, style: TextStyle(color: EsquemaColor.muted, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onStart, child: const Text('Hacer pedidos')),
          ],
        ),
      ),
    );
  }
}
