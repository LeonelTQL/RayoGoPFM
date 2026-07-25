import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/order_status_badge.dart';

class OrderManagementView extends StatefulWidget {
  const OrderManagementView({super.key});

  @override
  State<OrderManagementView> createState() => _OrderManagementViewState();
}

class _OrderManagementViewState extends State<OrderManagementView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<OrderViewModel>().loadAdminOrders();
      await context.read<OrderViewModel>().loadRiders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de pedidos')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadAdminOrders(),
              child: ListView.builder(
                itemCount: vm.orders.length,
                itemBuilder: (_, index) {
                  final order = vm.orders[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedido ${order.id.substring(0, 8)} - \$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Cliente: ${order.customerName ?? 'N/D'}'),
                          Text('Repartidor: ${order.riderName ?? 'Sin asignar'}'),
                          Text('Dirección: ${order.addressLine ?? 'N/D'}'),
                          OrderStatusBadge(status: order.status),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              DropdownButton<String>(
                                value: order.status,
                                items: const ['pendiente', 'confirmado', 'preparando', 'asignado', 'en_camino', 'entregado', 'cancelado']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (status) async {
                                  if (status != null) await context.read<OrderViewModel>().updateStatus(order.id, status);
                                },
                              ),
                              ElevatedButton(
                                onPressed: vm.riders.isEmpty
                                    ? null
                                    : () async {
                                        await context.read<OrderViewModel>().assignRider(order.id, vm.riders.first['id'].toString());
                                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(Text("Asignado a ${vm.riders.first['name']}") as SnackBar);
                                      },
                                child: const Text('Asignar repartidor'),
                              ),
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
