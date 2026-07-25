import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../widgets/cart_item_tile.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu carrito'),
        actions: [TextButton(onPressed: cart.items.isEmpty ? null : () => context.read<CartViewModel>().clear(), child: const Text('Vaciar'))],
      ),
      body: cart.items.isEmpty
          ? _EmptyCart(onStart: () => Navigator.pushReplacementNamed(context, AppRoutes.home))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundColor: EsquemaColor.chip, child: Icon(Icons.storefront, color: EsquemaColor.textPrimary)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(cart.restaurantName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: EsquemaColor.textPrimary))),
                            TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home), child: const Text('Ir al local')),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: EsquemaColor.chip, borderRadius: BorderRadius.circular(22)),
                        child: Row(
                          children: [
                            const Icon(Icons.delivery_dining, color: EsquemaColor.textPrimary),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Delivery · recibes en ${cart.items.first.product.deliveryWindow}', style: const TextStyle(fontWeight: FontWeight.w800, color: EsquemaColor.textSecondary))),
                            Text('Envío \$${cart.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...cart.items.map((item) => CartItemTile(
                            item: item,
                            onIncrement: () => context.read<CartViewModel>().increment(item.product),
                            onDecrement: () => context.read<CartViewModel>().decrement(item.product),
                            onRemove: () => context.read<CartViewModel>().remove(item.product),
                          )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('¿Te tienta algo más?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: EsquemaColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(22)),
                              child: const Row(
                                children: [
                                  Icon(Icons.local_offer, color: EsquemaColor.primary),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('El pedido mínimo depende de las condiciones del local.', style: TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.w700))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartViewModel cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
        decoration: const BoxDecoration(color: EsquemaColor.surface, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, -6))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!cart.canCheckout) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: EsquemaColor.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: Text('Agrega \$${cart.missingToMinOrder.toStringAsFixed(2)} más para completar el pedido mínimo de \$${cart.minOrderAmount.toStringAsFixed(2)}.', style: const TextStyle(fontWeight: FontWeight.w700, color: EsquemaColor.danger)),
              ),
              const SizedBox(height: 12),
            ],
            _RowAmount(label: 'Subtotal', amount: cart.subtotal),
            _RowAmount(label: 'Servicio plataforma', amount: cart.serviceFee),
            _RowAmount(label: 'Envío', amount: cart.deliveryFee),
            const Divider(height: 18, color: EsquemaColor.line),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: EsquemaColor.textPrimary)),
                const Spacer(),
                Text('\$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: EsquemaColor.primary)),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: cart.canCheckout ? () => Navigator.pushNamed(context, AppRoutes.checkout) : null,
              child: const Text('Ir a pagar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowAmount extends StatelessWidget {
  final String label;
  final double amount;
  const _RowAmount({required this.label, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: const TextStyle(color: EsquemaColor.textSecondary)), 
        const Spacer(), 
        Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: EsquemaColor.textPrimary))
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyCart({required this.onStart});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 86, color: EsquemaColor.muted),
            const SizedBox(height: 20),
            const Text('Aún no realizaste pedidos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: EsquemaColor.textPrimary)),
            const SizedBox(height: 10),
            const Text('Busca entre todas nuestras opciones y disfruta tu primer pedido.', textAlign: TextAlign.center, style: TextStyle(color: EsquemaColor.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onStart, child: const Text('Hacer pedido')),
          ],
        ),
      ),
    );
  }
}
