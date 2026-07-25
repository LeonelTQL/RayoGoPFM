import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasource/remote/socket_service.dart';
import '../../../domain/entities/order.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/order_status_badge.dart';

class DeliveryOrdersView extends StatefulWidget {
  const DeliveryOrdersView({super.key});

  @override
  State<DeliveryOrdersView> createState() => _DeliveryOrdersViewState();
}

class _DeliveryOrdersViewState extends State<DeliveryOrdersView> {
  bool showAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _refresh();
  }

  void _initSocket() async {
    final socket = context.read<SocketService>();
    await socket.init();
    
    socket.on('new_order_available', (data) {
      if (showAvailable && mounted) {
        _refresh();
      }
    });

    socket.on('order_taken', (data) {
      if (showAvailable && mounted) {
        _refresh();
      }
    });
  }

  void _refresh() {
    if (showAvailable) {
      context.read<OrderViewModel>().loadAdminOrders(); // O una ruta específica para pendientes
    } else {
      context.read<OrderViewModel>().loadDeliveryOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersVm = context.watch<OrderViewModel>();
    final displayOrders = showAvailable 
        ? ordersVm.orders.where((o) => o.status == 'pendiente').toList()
        : ordersVm.orders;

    return Scaffold(
      appBar: AppBar(
        title: Text(showAvailable ? 'Pedidos Disponibles' : 'Mis entregas'),
        actions: [
          IconButton(
            icon: Icon(showAvailable ? Icons.assignment : Icons.list_alt),
            onPressed: () {
              setState(() => showAvailable = !showAvailable);
              _refresh();
            },
            tooltip: showAvailable ? 'Ver mis entregas' : 'Ver pedidos disponibles',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<AuthViewModel>().logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
          )
        ],
      ),
      body: ordersVm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: displayOrders.isEmpty
                  ? Center(child: Text(showAvailable ? 'No hay pedidos disponibles por ahora.' : 'No tienes pedidos asignados.'))
                  : ListView.builder(
                      itemCount: displayOrders.length,
                      itemBuilder: (_, index) {
                        final order = displayOrders[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pedido ${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Cliente: ${order.customerName ?? 'N/D'}'),
                                Text('Dirección: ${order.addressLine ?? 'N/D'}'),
                                Text('Total: \$${order.total.toStringAsFixed(2)}'),
                                OrderStatusBadge(status: order.status),
                                const SizedBox(height: 10),
                                if (showAvailable)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EsquemaColor.primary,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () async {
                                        final ok = await context.read<OrderViewModel>().acceptOrder(order.id);
                                        if (ok) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Pedido aceptado correctamente.'),
                                                backgroundColor: EsquemaColor.success,
                                              ),
                                            );
                                            setState(() => showAvailable = false);
                                            _refresh();
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(context.read<OrderViewModel>().error ?? 'Error al aceptar.'),
                                                backgroundColor: EsquemaColor.danger,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('ACEPTAR PEDIDO'),
                                    ),
                                  )
                                 else if (order.status == 'entregado')
                                   Container(
                                     width: double.infinity,
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     alignment: Alignment.center,
                                     decoration: BoxDecoration(
                                       color: EsquemaColor.success.withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(16),
                                       border: Border.all(color: EsquemaColor.success.withOpacity(0.3)),
                                     ),
                                     child: const Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Icon(Icons.check_circle_outline, color: EsquemaColor.success, size: 20),
                                         SizedBox(width: 8),
                                         Text(
                                           'Entrega Completada',
                                           style: TextStyle(color: EsquemaColor.success, fontWeight: FontWeight.w900, fontSize: 15),
                                         ),
                                       ],
                                     ),
                                   )
                                 else if (order.status == 'cancelado')
                                   Container(
                                     width: double.infinity,
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     alignment: Alignment.center,
                                     decoration: BoxDecoration(
                                       color: EsquemaColor.danger.withOpacity(0.1),
                                       borderRadius: BorderRadius.circular(16),
                                       border: Border.all(color: EsquemaColor.danger.withOpacity(0.3)),
                                     ),
                                     child: const Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Icon(Icons.cancel_outlined, color: EsquemaColor.danger, size: 20),
                                         SizedBox(width: 8),
                                         Text(
                                           'Pedido Cancelado',
                                           style: TextStyle(color: EsquemaColor.danger, fontWeight: FontWeight.w900, fontSize: 15),
                                         ),
                                       ],
                                     ),
                                   )
                                 else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.deliveryMap, arguments: order.id),
                                          child: const Text('Mapa/GPS'),
                                        ),
                                        const SizedBox(height: 8),
                                        if (order.status == 'asignado') ...[
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                            onPressed: () async {
                                              await context.read<OrderViewModel>().updateStatus(order.id, 'en_camino');
                                              _refresh();
                                            },
                                            child: const Text('En camino'),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                          onPressed: () async {
                                            await context.read<DeliveryViewModel>().sendCurrentLocation(order.id);
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación enviada')));
                                          },
                                          child: const Text('Enviar GPS'),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.deliveryProof, arguments: order.id),
                                          child: const Text('Comprobante'),
                                        ),
                                      ],
                                    )
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
