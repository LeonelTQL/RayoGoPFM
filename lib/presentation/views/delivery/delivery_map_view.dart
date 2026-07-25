import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../themes/esquema_color.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/maps_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';

class DeliveryMapView extends StatefulWidget {
  const DeliveryMapView({super.key});

  @override
  State<DeliveryMapView> createState() => _DeliveryMapViewState();
}

class _DeliveryMapViewState extends State<DeliveryMapView> {
  String? orderId;
  LatLng? current;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderId ??= ModalRoute.of(context)!.settings.arguments as String?;
    if (!_loaded) {
      _loaded = true;
      Future.microtask(_loadPositionAndRoute);
    }
  }

  Future<void> _loadPositionAndRoute() async {
    final pos = await context.read<DeliveryViewModel>().getCurrentPosition();
    if (pos == null || !mounted) return;
    setState(() => current = LatLng(pos.latitude, pos.longitude));

    if (orderId == null) return;
    final orderVm = context.read<OrderViewModel>();
    await orderVm.loadOrder(orderId!);
    final order = orderVm.selectedOrder;
    if (order?.latitude != null && order?.longitude != null) {
      await context.read<MapsViewModel>().loadRoute(
            originLat: pos.latitude,
            originLng: pos.longitude,
            destinationLat: order!.latitude!,
            destinationLng: order.longitude!,
            travelMode: 'DRIVE',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = context.watch<DeliveryViewModel>();
    final order = context.watch<OrderViewModel>().selectedOrder;
    final route = context.watch<MapsViewModel>().activeRoute;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa del repartidor')),
      body: current == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (route != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.route, color: EsquemaColor.dark),
                        const SizedBox(width: 8),
                        Text('${route.distanceLabel} · ${route.durationLabel}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: current!, zoom: 16),
                    myLocationEnabled: true,
                    markers: {
                      Marker(markerId: const MarkerId('current'), position: current!, infoWindow: const InfoWindow(title: 'Mi ubicación')),
                      if (order?.latitude != null && order?.longitude != null)
                        Marker(markerId: const MarkerId('destination'), position: LatLng(order!.latitude!, order.longitude!), infoWindow: const InfoWindow(title: 'Entrega')),
                    },
                    polylines: {
                      if (route != null && route.points.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: route.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
                          width: 6,
                          color: EsquemaColor.primary,
                        ),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadPositionAndRoute,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar ruta'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: delivery.loading || orderId == null
                              ? null
                              : () async {
                                  final ok = await context.read<DeliveryViewModel>().sendCurrentLocation(orderId!);
                                  await _loadPositionAndRoute();
                                  if (context.mounted && ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación enviada al cliente')));
                                },
                          icon: const Icon(Icons.my_location),
                          label: const Text('Enviar GPS'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
