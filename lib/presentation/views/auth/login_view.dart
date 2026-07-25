import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../data/datasource/remote/socket_service.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> _handleGoogleSignIn(AuthViewModel auth) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final ok = await auth.loginWithGoogle(
        email: account.email,
        name: account.displayName ?? '',
        googleId: account.id,
        avatarUrl: account.photoUrl,
      );

      if (!mounted || !ok) return;
      context.read<SocketService>().init();
      _navigateBasedOnRole(auth.user!);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
  }

  void _navigateBasedOnRole(user) {
    if (user.isAdmin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (user.isDelivery) {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryOrders);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: EsquemaColor.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Hero(
                      tag: 'logo',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: EsquemaColor.background, // Mismo fondo negro que el splash
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: EsquemaColor.primary.withOpacity(0.3), // Resplandor cyan
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(10), // Padding interno para que logo.png no se corte
                            child: Image.asset(
                              'assets/images/logo.png', // Usamos logo.png que tiene fondo negro
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.bolt, size: 80, color: EsquemaColor.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'app_name',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'RayoGo',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: EsquemaColor.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Hero(
                    tag: 'app_subtitle',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Tu pedido, al instante',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: EsquemaColor.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _email,
                    label: 'Correo Electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : 'Ingrese un correo válido',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _password,
                    label: 'Contraseña',
                    obscureText: true,
                    validator: (v) => v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres',
                  ),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: EsquemaColor.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'INICIAR SESIÓN',
                    loading: auth.loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final ok = await auth.login(_email.text, _password.text);
                      if (!mounted || !ok) return;
                      context.read<SocketService>().init();
                      _navigateBasedOnRole(auth.user!);
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EsquemaColor.textPrimary,
                      side: const BorderSide(color: EsquemaColor.line),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Ingresar con Google'),
                    onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?', style: TextStyle(color: EsquemaColor.textSecondary)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(color: EsquemaColor.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
