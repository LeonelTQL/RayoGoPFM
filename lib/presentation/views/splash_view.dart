import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/esquema_color.dart';
import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/datasource/remote/socket_service.dart';
import 'auth/login_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthViewModel>();
    await Future.delayed(const Duration(seconds: 2)); // Para que se vea el logo
    await auth.loadSession();
    if (!mounted) return;
    
    final user = auth.user;
    if (user != null && mounted) {
      // Inicializar sockets si hay sesión
      context.read<SocketService>().init();
    }

    if (user == null) {
      // Usar PageRouteBuilder con desvanecimiento para que la transición Hero sea suave y visible
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else if (user.isAdmin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (user.isDelivery) {
      Navigator.pushReplacementNamed(context, AppRoutes.deliveryOrders);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EsquemaColor.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'logo',
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: EsquemaColor.background, // Mismo fondo negro de la app e imagen
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EsquemaColor.primary.withOpacity(0.2), // Resplandor cyan
                        blurRadius: 40,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12), // Margen interno para que no se corten las líneas cyan en el círculo
                      child: Image.asset(
                        'assets/images/logo.png', // Usamos logo.png que tiene fondo negro
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.bolt, size: 50, color: EsquemaColor.primary);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Hero(
                tag: 'app_name',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    'RayoGo',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: EsquemaColor.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const Hero(
                tag: 'app_subtitle',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    'Tu pedido, al instante',
                    style: TextStyle(
                      fontSize: 18,
                      color: EsquemaColor.primary,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(EsquemaColor.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
