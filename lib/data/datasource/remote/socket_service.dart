import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/config/app_config.dart';
import '../../../core/services/notification_service.dart';
import '../local/session_local_datasource.dart';

class SocketService {
  final SessionLocalDatasource session;
  io.Socket? _socket;
  final NotificationService _notifications = NotificationService();

  SocketService(this.session);

  Future<void> init() async {
    if (_socket != null && _socket!.connected) return;

    final token = await session.getToken();
    if (token == null) return;

    _socket = io.io(AppConfig.apiBaseUrl.replaceFirst('/api', ''), 
      io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build()
    );

    _socket?.onConnect((_) => print('Connected to Socket.io server'));
    
    // --- LÓGICA DE NOTIFICACIONES AUTOMÁTICAS ---
    
    // Cuando a un cliente le aceptan un pedido
    _socket?.on('order_accepted', (data) {
      final orderId = data['id'] ?? data['orderId'];
      _notifications.showNotification(
        id: 1,
        title: '¡Pedido Aceptado! 🛵',
        body: 'Un repartidor ha tomado tu pedido y pronto estará en camino.',
        payload: orderId?.toString(),
      );
    });

    // Cuando el estado del pedido cambia (En camino, entregado, etc)
    _socket?.on('order_status_updated', (data) {
      final orderId = data['id'] ?? data['orderId'];
      String status = data['status'] ?? '';
      String title = 'Actualización de tu pedido';
      String body = 'Tu pedido ha cambiado de estado.';

      if (status == 'en_camino') {
        title = '¡Tu pedido va en camino! 🏁';
        body = 'El repartidor ya salió con tu entrega.';
      } else if (status == 'entregado') {
        title = '¡Pedido Entregado! ✨';
        body = '¡Que lo disfrutes! No olvides calificar el servicio.';
      }

      _notifications.showNotification(
        id: 2, 
        title: title, 
        body: body,
        payload: orderId?.toString(),
      );
    });

    // Notificación de proximidad (cuando el repartidor está cerca)
    _socket?.on('rider_nearby', (data) {
      final orderId = data['id'] ?? data['orderId'];
      _notifications.showNotification(
        id: 3,
        title: '¡Ya casi llega! 📍',
        body: 'Tu repartidor está a menos de 500 metros de tu ubicación.',
        payload: orderId?.toString(),
      );
    });

    // Para Repartidores: Nuevo pedido disponible
    _socket?.on('new_order_available', (data) {
      _notifications.showNotification(
        id: 4,
        title: '¡Nuevo Pedido Disponible! 💰',
        body: 'Hay un nuevo pedido cerca de ti. ¡Acéptalo ahora!',
      );
    });

    _socket?.onDisconnect((_) => print('Disconnected from Socket.io server'));
    _socket?.onConnectError((err) => print('Connection error: $err'));
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
