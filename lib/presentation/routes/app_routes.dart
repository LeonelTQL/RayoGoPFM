import 'package:flutter/material.dart';
import '../views/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/client/home_view.dart';
import '../views/client/search_view.dart';
import '../views/client/promotions_view.dart';
import '../views/client/product_detail_view.dart';
import '../views/client/cart_view.dart';
import '../views/client/checkout_view.dart';
import '../views/client/tracking_view.dart';
import '../views/client/order_history_view.dart';
import '../views/client/profile_view.dart';
import '../views/delivery/delivery_orders_view.dart';
import '../views/delivery/delivery_map_view.dart';
import '../views/delivery/delivery_proof_view.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/admin/product_form_view.dart';
import '../views/admin/order_management_view.dart';
import '../views/admin/user_management_view.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const search = '/search';
  static const promotions = '/promotions';
  static const productDetail = '/product-detail';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const tracking = '/tracking';
  static const history = '/history';
  static const profile = '/profile';
  static const deliveryOrders = '/delivery/orders';
  static const deliveryMap = '/delivery/map';
  static const deliveryProof = '/delivery/proof';
  static const adminDashboard = '/admin/dashboard';
  static const adminProductForm = '/admin/product-form';
  static const adminOrders = '/admin/orders';
  static const adminUsers = '/admin/users';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashView(),
        login: (_) => const LoginView(),
        register: (_) => const RegisterView(),
        home: (_) => const HomeView(),
        search: (_) => const SearchView(),
        promotions: (_) => const PromotionsView(),
        productDetail: (_) => const ProductDetailView(),
        cart: (_) => const CartView(),
        checkout: (_) => const CheckoutView(),
        tracking: (_) => const TrackingView(),
        history: (_) => const OrderHistoryView(),
        profile: (_) => const ProfileView(),
        deliveryOrders: (_) => const DeliveryOrdersView(),
        deliveryMap: (_) => const DeliveryMapView(),
        deliveryProof: (_) => const DeliveryProofView(),
        adminDashboard: (_) => const AdminDashboardView(),
        adminProductForm: (_) => const ProductFormView(),
        adminOrders: (_) => const OrderManagementView(),
        adminUsers: (_) => const UserManagementView(),
      };
}
