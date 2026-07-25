import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../widgets/custom_text_field.dart';

class ProductFormView extends StatefulWidget {
  const ProductFormView({super.key});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(controller: _name, label: 'Nombre', validator: (v) => v != null && v.length >= 2 ? null : 'Nombre requerido'),
              const SizedBox(height: 12),
              CustomTextField(controller: _description, label: 'Descripción', maxLines: 3),
              const SizedBox(height: 12),
              CustomTextField(controller: _price, label: 'Precio', keyboardType: TextInputType.number, validator: (v) => double.tryParse(v ?? '') != null && double.parse(v!) > 0 ? null : 'Precio inválido'),
              const SizedBox(height: 12),
              CustomTextField(controller: _stock, label: 'Stock', keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') != null && int.parse(v!) >= 0 ? null : 'Stock inválido'),
              const SizedBox(height: 12),
              CustomTextField(controller: _imageUrl, label: 'URL de imagen opcional'),
              if (vm.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(vm.error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await context.read<ProductViewModel>().createProduct(
                              name: _name.text,
                              description: _description.text,
                              price: double.parse(_price.text),
                              stock: int.parse(_stock.text),
                              imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
                            );
                        if (!mounted || !ok) return;
                        Navigator.pop(context);
                      },
                child: vm.loading ? const CircularProgressIndicator() : const Text('Guardar producto'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
