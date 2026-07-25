import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../widgets/custom_text_field.dart';

class DeliveryProofView extends StatefulWidget {
  const DeliveryProofView({super.key});

  @override
  State<DeliveryProofView> createState() => _DeliveryProofViewState();
}

class _DeliveryProofViewState extends State<DeliveryProofView> {
  final _note = TextEditingController();
  File? _image;
  String? orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    orderId ??= ModalRoute.of(context)!.settings.arguments as String?;
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DeliveryViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de entrega')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: _image == null ? const Center(child: Icon(Icons.camera_alt, size: 80)) : Image.file(_image!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Tomar foto')),
            const SizedBox(height: 12),
            CustomTextField(controller: _note, label: 'Nota de entrega', maxLines: 3),
            if (vm.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(vm.error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: vm.loading || _image == null || orderId == null
                  ? null
                  : () async {
                      final ok = await context.read<DeliveryViewModel>().uploadProof(orderId: orderId!, image: _image!, note: _note.text);
                      if (!mounted || !ok) return;
                      await context.read<OrderViewModel>().loadDeliveryOrders();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega registrada')));
                    },
              child: vm.loading ? const CircularProgressIndicator() : const Text('Finalizar entrega'),
            ),
          ],
        ),
      ),
    );
  }
}
