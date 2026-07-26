import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/address_picker_sheet.dart';
import '../../widgets/custom_text_field.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _note = TextEditingController();
  String _payment = 'efectivo';
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AddressViewModel>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _openAddressSheet() {
    final addressVm = context.read<AddressViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressPickerSheet(
        selectedAddress: addressVm.selectedAddress,
        onSelected: addressVm.select,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final orderVm = context.watch<OrderViewModel>();
    final addressVm = context.watch<AddressViewModel>();
    final selectedAddress = addressVm.selectedAddress;
    final total = cart.total;

    return Scaffold(
      appBar: AppBar(title: const Text('Último paso')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('¿Cómo quieres pagar?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: EsquemaColor.textPrimary)),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 154,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _PaymentCard(value: 'efectivo', title: 'Efectivo', subtitle: 'Pagas al recibir', icon: Icons.payments_outlined, selected: _payment == 'efectivo', onTap: () => setState(() => _payment = 'efectivo')),
                        _PaymentCard(value: 'transferencia', title: 'Transferencia', subtitle: 'Sube comprobante', icon: Icons.account_balance_outlined, selected: _payment == 'transferencia', onTap: () => setState(() => _payment = 'transferencia')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Datos de entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: EsquemaColor.textPrimary)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.delivery_dining, title: 'Delivery', subtitle: cart.items.first.product.deliveryWindow),
                  const SizedBox(height: 10),
                  _AddressSelector(
                    selectedLabel: selectedAddress?.label,
                    selectedLine: selectedAddress?.addressLine,
                    loading: addressVm.loading,
                    onTap: _openAddressSheet,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _note, label: 'Instrucciones de entrega', maxLines: 3),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: EsquemaColor.chip, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumen interno del negocio', style: TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Comisión restaurante: ${(cart.commissionRate * 100).toStringAsFixed(0)}%  ·  Comisión estimada: \$${cart.estimatedRestaurantCommission.toStringAsFixed(2)}', style: const TextStyle(color: EsquemaColor.textSecondary, fontSize: 13)),
                        Text('Liquidación estimada al restaurante: \$${cart.estimatedRestaurantPayout.toStringAsFixed(2)}', style: const TextStyle(color: EsquemaColor.textSecondary, fontSize: 13)),
                        Text('Pedido mínimo del local: \$${cart.minOrderAmount.toStringAsFixed(2)}.', style: const TextStyle(color: EsquemaColor.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (orderVm.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(orderVm.error!, style: const TextStyle(color: EsquemaColor.danger))),
                ],
              ),
            ),
      bottomSheet: cart.items.isEmpty ? null : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          decoration: const BoxDecoration(color: EsquemaColor.surface, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -6))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: EsquemaColor.textPrimary)),
                  const Spacer(),
                  Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: EsquemaColor.primary)),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: orderVm.loading
                    ? null
                    : () async {
                        if (!cart.canCheckout) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('El subtotal mínimo para este local es \$${cart.minOrderAmount.toStringAsFixed(2)}.')));
                          return;
                        }
                        final address = context.read<AddressViewModel>().selectedAddress;
                        if (address == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona o registra una dirección de entrega.')));
                          return;
                        }
                        final ok = await context.read<OrderViewModel>().createOrderWithAddressId(
                              deliveryAddressId: address.id,
                              paymentMethod: _payment,
                              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                              items: cart.items,
                            );
                        if (!context.mounted || !ok) return;
                        context.read<CartViewModel>().clear();
                        Navigator.pushReplacementNamed(context, AppRoutes.tracking, arguments: context.read<OrderViewModel>().selectedOrder!.id);
                      },
                child: orderVm.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Pagar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentCard({required this.value, required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: selected ? EsquemaColor.primary : EsquemaColor.chip,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? EsquemaColor.primary : EsquemaColor.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.black : EsquemaColor.textPrimary, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: selected ? Colors.black : EsquemaColor.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: selected ? Colors.black54 : EsquemaColor.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressSelector extends StatelessWidget {
  final String? selectedLabel;
  final String? selectedLine;
  final bool loading;
  final VoidCallback onTap;
  const _AddressSelector({required this.selectedLabel, required this.selectedLine, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: EsquemaColor.chip, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: EsquemaColor.primary),
            const SizedBox(width: 14),
            Expanded(
              child: loading
                  ? const Text('Cargando direcciones...', style: TextStyle(color: EsquemaColor.textSecondary))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedLabel ?? 'Seleccionar dirección', style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)),
                        const SizedBox(height: 2),
                        Text(selectedLine ?? 'Agrega una dirección desde la base de datos.', style: const TextStyle(color: EsquemaColor.textSecondary, fontSize: 13)),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, color: EsquemaColor.muted),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoRow({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero, 
      leading: Icon(icon, color: EsquemaColor.textSecondary), 
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)), 
      subtitle: Text(subtitle, style: const TextStyle(color: EsquemaColor.textSecondary))
    );
  }
}
