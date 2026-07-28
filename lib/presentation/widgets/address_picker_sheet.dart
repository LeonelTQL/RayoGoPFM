import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/map_place.dart';
import '../../themes/esquema_color.dart';
import '../viewmodels/address_viewmodel.dart';
import '../viewmodels/delivery_viewmodel.dart';
import '../viewmodels/maps_viewmodel.dart';
import 'custom_text_field.dart';

class AddressPickerSheet extends StatefulWidget {
  final Address? selectedAddress;
  final ValueChanged<Address> onSelected;

  const AddressPickerSheet({
    super.key,
    required this.selectedAddress,
    required this.onSelected,
  });

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  bool _adding = false;
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _addressLine = TextEditingController();
  final _search = TextEditingController();
  double? _lat;
  double? _lng;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void dispose() {
    _label.dispose();
    _addressLine.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    final position = await context.read<DeliveryViewModel>().getCurrentPosition(context);
    if (!context.mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación GPS.')),
      );
      return;
    }

    final place = await context.read<MapsViewModel>().reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (!context.mounted) return;
    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
      if (place?.formattedAddress != null && place!.formattedAddress!.isNotEmpty) {
        _addressLine.text = place.formattedAddress!;
      }
      if (_label.text.trim().isEmpty) _label.text = 'Mi ubicación';
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: LatLng(position.latitude, position.longitude),
        )
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _selectPrediction(MapPlace prediction) async {
    final place = await context.read<MapsViewModel>().selectPrediction(prediction);
    if (!context.mounted || place == null || !place.hasCoordinates) return;
    setState(() {
      _lat = place.latitude;
      _lng = place.longitude;
      _addressLine.text = place.formattedAddress ?? place.description;
      if (_label.text.trim().isEmpty) _label.text = place.name ?? place.mainText;
      _search.text = place.description;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: LatLng(place.latitude!, place.longitude!),
        )
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.latitude!, place.longitude!),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
        )
      };
    });

    final place = await context.read<MapsViewModel>().reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (!context.mounted) return;
    if (place != null && place.formattedAddress != null) {
      setState(() {
        _addressLine.text = place.formattedAddress!;
        if (_label.text.trim().isEmpty) _label.text = place.name ?? 'Mi ubicación';
      });
    }
  }

  Future<void> _confirmDeleteAddress(BuildContext context, AddressViewModel vm, Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EsquemaColor.surface,
        title: const Text('Eliminar dirección', style: TextStyle(color: EsquemaColor.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar la dirección "${address.label}"?', style: const TextStyle(color: EsquemaColor.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: EsquemaColor.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EsquemaColor.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await vm.deleteAddress(address.id);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dirección eliminada correctamente.'), backgroundColor: EsquemaColor.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Error al eliminar.'), backgroundColor: EsquemaColor.danger),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dirección de Google Maps o captura tu GPS.')),
      );
      return;
    }
    final address = await context.read<AddressViewModel>().createAddress(
          label: _label.text.trim(),
          addressLine: _addressLine.text.trim(),
          latitude: _lat!,
          longitude: _lng!,
          isDefault: true,
        );
    if (!context.mounted || address == null) return;
    widget.onSelected(address);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddressViewModel>();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
      padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: EsquemaColor.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _adding ? _buildForm(vm) : _buildList(vm),
    );
  }

  Widget _buildList(AddressViewModel vm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Elige tu dirección', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: EsquemaColor.textPrimary))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 30, color: EsquemaColor.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.loading)
          const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
        else if (vm.addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Icon(Icons.location_off_outlined, size: 56, color: EsquemaColor.muted),
                SizedBox(height: 12),
                Text('No tienes direcciones registradas.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: EsquemaColor.textPrimary)),
                SizedBox(height: 4),
                Text('Agrega una dirección para poder registrar pedidos.', textAlign: TextAlign.center, style: TextStyle(color: EsquemaColor.muted)),
              ],
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vm.addresses.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: EsquemaColor.line),
              itemBuilder: (_, index) {
                final address = vm.addresses[index];
                final selected = widget.selectedAddress?.id == address.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(selected ? Icons.check_circle : Icons.location_on_outlined, color: selected ? EsquemaColor.primary : EsquemaColor.textSecondary),
                  title: Text(address.label, style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)),
                  subtitle: Text(address.addressLine, style: const TextStyle(color: EsquemaColor.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: EsquemaColor.danger),
                    onPressed: () => _confirmDeleteAddress(context, vm, address),
                  ),
                  onTap: () {
                    widget.onSelected(address);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _adding = true),
          icon: const Icon(Icons.add),
          label: const Text('Agregar dirección'),
        ),
      ],
    );
  }

  Widget _buildForm(AddressViewModel vm) {
    final mapsVm = context.watch<MapsViewModel>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _adding = false), icon: const Icon(Icons.arrow_back, color: EsquemaColor.textPrimary)),
              const Expanded(child: Text('Agregar dirección', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: EsquemaColor.textPrimary))),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _search,
            style: const TextStyle(color: EsquemaColor.textPrimary),
            decoration: InputDecoration(
              labelText: 'Buscar con Google Maps',
              labelStyle: const TextStyle(color: EsquemaColor.textSecondary),
              hintText: 'Ej: Av. Amazonas y Naciones Unidas',
              hintStyle: const TextStyle(color: EsquemaColor.muted),
              prefixIcon: const Icon(Icons.search, color: EsquemaColor.primary),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: EsquemaColor.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: EsquemaColor.primary)),
            ),
            onChanged: (value) => context.read<MapsViewModel>().autocomplete(value),
          ),
          if (mapsVm.loading)
            const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          if (mapsVm.predictions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(color: EsquemaColor.card, border: Border.all(color: EsquemaColor.line), borderRadius: BorderRadius.circular(18)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mapsVm.predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: EsquemaColor.line),
                itemBuilder: (_, index) {
                  final item = mapsVm.predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined, color: EsquemaColor.primary),
                    title: Text(item.mainText, style: const TextStyle(fontWeight: FontWeight.w800, color: EsquemaColor.textPrimary)),
                    subtitle: item.secondaryText.isEmpty ? null : Text(item.secondaryText, style: const TextStyle(color: EsquemaColor.textSecondary)),
                    onTap: () => _selectPrediction(item),
                  );
                },
              ),
            ),
          if (mapsVm.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(mapsVm.error!, style: const TextStyle(color: EsquemaColor.danger)),
            ),
          const SizedBox(height: 12),
          
          // Map Container
          Container(
            height: 240, // Un poco más de presencia
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: EsquemaColor.line, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_lat ?? -0.180653, _lng ?? -78.467838),
                  zoom: 16,
                ),
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                // Esto es CLAVE: Permite mover el mapa dentro del BottomSheet
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _label,
                    label: 'Etiqueta',
                    validator: (value) => value == null || value.trim().length < 2 ? 'Etiqueta requerida.' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _addressLine,
                    label: 'Dirección',
                    maxLines: 2,
                    validator: (value) => value == null || value.trim().length < 5 ? 'Dirección requerida.' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _captureGps,
                    icon: const Icon(Icons.my_location),
                    label: Text(_lat == null ? 'Usar mi GPS actual' : 'GPS capturado: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: vm.loading ? null : _saveAddress,
                    child: vm.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar dirección'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
