import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../widgets/address_picker_sheet.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/product_card.dart';
import '../../widgets/promo_banner.dart';
import '../../widgets/section_title.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ProductViewModel>().loadProducts();
      await context.read<AddressViewModel>().loadAddresses();
    });
  }

  void _openAddressSheet() {
    final addressVm = context.read<AddressViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressPickerSheet(
        selectedAddress: addressVm.selectedAddress,
        onSelected: addressVm.select,
      ),
    );
  }

  void _addProduct(Product product) {
    final ok = context.read<CartViewModel>().add(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${product.name} agregado al carrito' : 'Solo puedes comprar de un local por pedido.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final productsVm = context.watch<ProductViewModel>();
    final addressVm = context.watch<AddressViewModel>();
    final cart = context.watch<CartViewModel>();
    final products = productsVm.products;
    final promos = productsVm.discountedProducts.take(8).toList();
    final popular = productsVm.popularProducts;
    final categories = productsVm.categories;
    final selectedAddress = addressVm.selectedAddress;
    final addressLabel = selectedAddress == null ? 'Agregar dirección' : selectedAddress.label;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          await productsVm.loadProducts();
          await addressVm.loadAddresses();
        },
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                address: addressLabel,
                cartCount: cart.count,
                onAddressTap: _openAddressSheet,
                topPadding: MediaQuery.of(context).padding.top,
              ),
            ),
            if (productsVm.loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (productsVm.error != null)
              SliverFillRemaining(child: Center(child: Text(productsVm.error!)))
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyHome(onReload: () => productsVm.loadProducts()),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (promos.isNotEmpty) ...[
                        PromoBanner(
                          title: 'Hasta ${promos.first.discountPercent}% OFF',
                          subtitle: '${promos.first.name} · ${promos.first.restaurantDisplayName}',
                          badge: 'Pedido mín. \$${promos.first.minOrderAmount.toStringAsFixed(2)}',
                          icon: Icons.local_offer_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (categories.isNotEmpty) ...[
                        const SectionTitle(title: 'Categorías'),
                        _CategoryList(categories: categories, onTap: (category) => Navigator.pushNamed(context, AppRoutes.search, arguments: category)),
                      ],
                      if (popular.isNotEmpty) ...[
                        SectionTitle(title: 'Los más populares', action: 'Ver todo', onAction: () => Navigator.pushNamed(context, AppRoutes.search)),
                        SizedBox(
                          height: 195, // Incrementado de 178 para dar margen a desbordes de texto
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: popular.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (_, index) => _RestaurantCard(product: popular[index]),
                          ),
                        ),
                      ],
                      const SectionTitle(title: 'Descubre estas opciones'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .62), // Ajustado de .52 a .50 para prevenir desbordamientos verticales por completo
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product),
                        onAdd: () => _addProduct(product),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
              if (promos.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'Promociones disponibles'),
                        SizedBox(
                          height: 290,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: promos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (_, index) => ProductCard(
                              compact: true,
                              product: promos[index],
                              onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: promos[index]),
                              onAdd: () => _addProduct(promos[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String address;
  final int cartCount;
  final VoidCallback onAddressTap;
  final double topPadding;

  _HomeHeaderDelegate({
    required this.address,
    required this.cartCount,
    required this.onAddressTap,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _Header(address: address, cartCount: cartCount, onAddressTap: onAddressTap);
  }

  @override
  double get maxExtent => topPadding + 172;

  @override
  double get minExtent => topPadding + 172;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.address != address || oldDelegate.cartCount != cartCount || oldDelegate.topPadding != topPadding;
  }
}

class _Header extends StatelessWidget {
  final String address;
  final int cartCount;
  final VoidCallback onAddressTap;
  const _Header({required this.address, required this.cartCount, required this.onAddressTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        color: EsquemaColor.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Address Selector Pill
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: onAddressTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: EsquemaColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: EsquemaColor.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: EsquemaColor.primary, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              address,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EsquemaColor.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: EsquemaColor.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Notification Button
              Container(
                decoration: BoxDecoration(
                  color: EsquemaColor.chip,
                  shape: BoxShape.circle,
                  border: Border.all(color: EsquemaColor.line.withOpacity(0.5), width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded, color: EsquemaColor.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              
              // Cart Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: EsquemaColor.chip,
                      shape: BoxShape.circle,
                      border: Border.all(color: EsquemaColor.line.withOpacity(0.5), width: 1),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                      icon: const Icon(Icons.shopping_cart_outlined, color: EsquemaColor.textPrimary, size: 20),
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: EsquemaColor.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Custom Search Box
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: EsquemaColor.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: EsquemaColor.line.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: EsquemaColor.muted, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Buscar locales, platos o productos...',
                      style: TextStyle(
                        color: EsquemaColor.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EsquemaColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: EsquemaColor.primary, size: 18),
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

class _CategoryList extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onTap;
  const _CategoryList({required this.categories, required this.onTap});

  IconData _iconFor(String category) {
    final value = category.toLowerCase();
    if (value.contains('sushi')) return Icons.set_meal_rounded;
    if (value.contains('burger') || value.contains('hamburg')) return Icons.lunch_dining_rounded;
    if (value.contains('bebida')) return Icons.local_drink_rounded;
    if (value.contains('postre')) return Icons.cake_rounded;
    if (value.contains('súper') || value.contains('super')) return Icons.shopping_basket_rounded;
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final category = categories[index];
          return InkWell(
            onTap: () => onTap(category),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EsquemaColor.card, EsquemaColor.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: EsquemaColor.line.withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFor(category), size: 28, color: EsquemaColor.primary),
                  const SizedBox(height: 6),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: EsquemaColor.textPrimary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Product product;
  const _RestaurantCard({required this.product});

  @override
  Widget build(BuildContext context) {
    const cardBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
      topRight: Radius.circular(6),
      bottomLeft: Radius.circular(6),
    );

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.search, arguments: product.restaurantDisplayName),
      borderRadius: cardBorderRadius,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EsquemaColor.card, EsquemaColor.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: cardBorderRadius,
          border: Border.all(color: EsquemaColor.line.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child: Container(
                height: 95,
                width: double.infinity,
                color: EsquemaColor.chip,
                child: product.restaurantCoverUrl == null
                    ? const Icon(Icons.storefront, size: 48, color: EsquemaColor.muted)
                    : Image.network(
                        product.restaurantCoverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 48),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.restaurantDisplayName, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: EsquemaColor.textPrimary)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: EsquemaColor.warning),
                      const SizedBox(width: 2),
                      Text(
                        ' ${product.restaurantRating.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: EsquemaColor.textPrimary, fontSize: 12),
                      ),
                      const Text(' · ', style: TextStyle(color: EsquemaColor.muted)),
                      Expanded(
                        child: Text(
                          product.deliveryWindow, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: EsquemaColor.muted, fontSize: 11)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 13, color: EsquemaColor.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Envío: \$${product.deliveryFee.toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.w800, color: EsquemaColor.primary, fontSize: 12)
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final Future<void> Function() onReload;
  const _EmptyHome({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined, size: 78, color: EsquemaColor.muted),
          const SizedBox(height: 18),
          const Text('No hay productos disponibles', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: EsquemaColor.textPrimary)),
          const SizedBox(height: 8),
          const Text('Cuando el administrador cargue restaurantes, categorías y productos desde la base de datos, se mostrarán aquí.', textAlign: TextAlign.center, style: TextStyle(color: EsquemaColor.textSecondary)),
          const SizedBox(height: 22),
          OutlinedButton.icon(onPressed: onReload, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
        ],
      ),
    );
  }
}
