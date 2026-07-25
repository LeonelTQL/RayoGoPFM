import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/datasource/remote/socket_service.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _name,
                label: 'Nombre completo',
                errorText: auth.fieldErrors['name'],
                onChanged: (_) => auth.fieldErrors.remove('name'),
                validator: (v) => v != null && v.length >= 3 ? null : 'Mínimo 3 caracteres',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _email,
                label: 'Correo',
                keyboardType: TextInputType.emailAddress,
                errorText: auth.fieldErrors['email'],
                onChanged: (_) => auth.fieldErrors.remove('email'),
                validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _phone,
                label: 'Teléfono',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                errorText: auth.fieldErrors['phone'],
                onChanged: (_) => auth.fieldErrors.remove('phone'),
                validator: (v) => v != null && v.length == 10 ? null : 'Deben ser 10 dígitos',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _password,
                label: 'Contraseña',
                obscureText: true,
                errorText: auth.fieldErrors['password'],
                onChanged: (_) => auth.fieldErrors.remove('password'),
                validator: (v) => v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmPassword,
                label: 'Confirmar contraseña',
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Repita la contraseña';
                  if (v != _password.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 18),
              CustomButton(
                text: 'Registrarme',
                loading: auth.loading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final ok = await auth.register(
                    name: _name.text,
                    email: _email.text,
                    password: _password.text,
                    phone: _phone.text,
                  );
                  if (!mounted || !ok) return;
                  context.read<SocketService>().init();
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
