import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/maps_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/order_status_badge.dart';
import '../../routes/app_routes.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  String? orderId;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderId ??= ModalRoute.of(context)!.settings.arguments as String?;
    if (!_loaded && orderId != null) {
      _loaded = true;
      Future.microtask(_loadData);
    }
  }

  Future<void> _loadData() async {
    final orderVm = context.read<OrderViewModel>();
    final deliveryVm = context.read<DeliveryViewModel>();
    final mapsVm = context.read<MapsViewModel>();

    await orderVm.loadOrder(orderId!);
    await deliveryVm.loadLatestLocation(orderId!);

    final order = orderVm.selectedOrder;
    final location = deliveryVm.latest;
    if (order?.latitude != null && order?.longitude != null && location != null) {
      await mapsVm.loadRoute(
        originLat: location.latitude,
        originLng: location.longitude,
        destinationLat: order!.latitude!,
        destinationLng: order.longitude!,
        travelMode: 'DRIVE',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderVm = context.watch<OrderViewModel>();
    final deliveryVm = context.watch<DeliveryViewModel>();
    final mapsVm = context.watch<MapsViewModel>();
    final order = orderVm.selectedOrder;
    final location = deliveryVm.latest;
    final route = mapsVm.activeRoute;

    if (orderVm.loading || order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDelivered = order.status == 'entregado';
    final isCancelled = order.status == 'cancelado';
    if (isDelivered || isCancelled) {
      return Scaffold(
        appBar: AppBar(title: Text(isDelivered ? 'Pedido Entregado' : 'Pedido Cancelado')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDelivered ? EsquemaColor.success : EsquemaColor.danger).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDelivered ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                    size: 100,
                    color: isDelivered ? EsquemaColor.success : EsquemaColor.danger,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isDelivered ? '¡Tu pedido ha sido entregado!' : '¡Tu pedido ha sido cancelado!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: EsquemaColor.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isDelivered
                      ? 'Entregado por: ${order.riderName ?? 'nuestro repartidor'}'
                      : 'Lamentamos los inconvenientes con tu pedido.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EsquemaColor.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                
                // Resumen del pedido
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: EsquemaColor.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EsquemaColor.line.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Pedido', value: '#${order.id.substring(0, 8).toUpperCase()}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: EsquemaColor.line, height: 1),
                      ),
                      _SummaryRow(label: 'Total pagado', value: '\$${order.total.toStringAsFixed(2)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: EsquemaColor.line, height: 1),
                      ),
                      _SummaryRow(label: 'Dirección de entrega', value: order.addressLine ?? 'Sin dirección'),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EsquemaColor.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                    child: const Text('Volver al inicio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido ${order.id.substring(0, 8)}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                OrderStatusBadge(status: order.status),
                const SizedBox(height: 8),
                Text('Total: \$${order.total.toStringAsFixed(2)}'),
                Text('Dirección: ${order.addressLine ?? 'Sin dirección'}'),
                Text('Repartidor: ${order.riderName ?? 'Aún no asignado'}'),
                if (route != null) Text('Ruta: ${route.distanceLabel} · ${route.durationLabel}'),
                if (mapsVm.error != null) Text(mapsVm.error!, style: const TextStyle(color: EsquemaColor.danger)),
              ],
            ),
          ),
          Expanded(
            child: location == null
                ? const Center(child: Text('Aún no hay ubicación del repartidor.'))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(location.latitude, location.longitude), zoom: 15),
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('rider'),
                        position: LatLng(location.latitude, location.longitude),
                        infoWindow: const InfoWindow(title: 'Repartidor'),
                      ),
                      if (order.latitude != null && order.longitude != null)
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: LatLng(order.latitude!, order.longitude!),
                          infoWindow: const InfoWindow(title: 'Entrega'),
                        ),
                    },
                    polylines: {
                      if (route != null && route.points.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('delivery_route'),
                          points: route.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
                          width: 6,
                          color: EsquemaColor.primary,
                        ),
                      if ((route == null || route.points.isEmpty) && order.latitude != null && order.longitude != null)
                        Polyline(
                          polylineId: const PolylineId('direct_route'),
                          points: [LatLng(location.latitude, location.longitude), LatLng(order.latitude!, order.longitude!)],
                          width: 4,
                          color: EsquemaColor.muted,
                        ),
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: EsquemaColor.muted, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: EsquemaColor.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
