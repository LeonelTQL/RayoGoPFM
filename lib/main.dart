import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/datasource/local/session_local_datasource.dart';
import 'data/datasource/remote/api_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/address_repository_impl.dart';
import 'data/repositories/delivery_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/datasource/remote/maps_remote_datasource.dart';
import 'data/repositories/maps_repository_impl.dart';
import 'data/datasource/remote/socket_service.dart';
import 'presentation/routes/app_routes.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/address_viewmodel.dart';
import 'presentation/viewmodels/cart_viewmodel.dart';
import 'presentation/viewmodels/delivery_viewmodel.dart';
import 'presentation/viewmodels/order_viewmodel.dart';
import 'presentation/viewmodels/product_viewmodel.dart';
import 'presentation/viewmodels/maps_viewmodel.dart';
import 'themes/theme_general.dart';
import 'core/services/notification_service.dart';
import 'core/utils/navigation_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Notificaciones
  await NotificationService().init();

  final session = SessionLocalDatasource();
  final apiClient = ApiClient(session: session);
  final socketService = SocketService(session);

  runApp(SmartDeliveryApp(session: session, apiClient: apiClient, socketService: socketService));
}

class SmartDeliveryApp extends StatelessWidget {
  final SessionLocalDatasource session;
  final ApiClient apiClient;
  final SocketService socketService;

  const SmartDeliveryApp({super.key, required this.session, required this.apiClient, required this.socketService});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(apiClient: apiClient, session: session);
    final productRepository = ProductRepositoryImpl(apiClient);
    final addressRepository = AddressRepositoryImpl(apiClient);
    final orderRepository = OrderRepositoryImpl(apiClient);
    final deliveryRepository = DeliveryRepositoryImpl(apiClient);
    final mapsRepository = MapsRepositoryImpl(MapsRemoteDatasource(apiClient));

    return MultiProvider(
      providers: [
        Provider.value(value: socketService),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)..loadSession()),
        ChangeNotifierProvider(create: (_) => ProductViewModel(productRepository)),
        ChangeNotifierProvider(create: (_) => AddressViewModel(addressRepository)),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel(orderRepository)),
        ChangeNotifierProvider(create: (_) => DeliveryViewModel(deliveryRepository)),
        ChangeNotifierProvider(create: (_) => MapsViewModel(mapsRepository)),
      ],
      child: MaterialApp(
        navigatorKey: NavigationUtils.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Smart Delivery',
        theme: ThemeGeneral.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
