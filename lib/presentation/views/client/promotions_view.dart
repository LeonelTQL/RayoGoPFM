import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../widgets/app_bottom_nav.dart';

class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key});

  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductViewModel>().loadProducts();
    });
  }

  void _addProduct(BuildContext context, Product product) {
    final ok = context.read<CartViewModel>().add(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${product.name} agregado al carrito' : 'Solo puedes comprar de un local por pedido.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final productsVm = context.watch<ProductViewModel>();
    final products = productsVm.discountedProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupones y Ofertas'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            icon: const Icon(Icons.shopping_cart_outlined),
          )
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: productsVm.loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(34),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 74, color: EsquemaColor.muted),
                        SizedBox(height: 16),
                        Text(
                          'No hay promociones activas',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EsquemaColor.textPrimary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vuelve más tarde para descubrir cupones y ofertas disponibles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: EsquemaColor.muted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Espacio para el nav flotante
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _PromoTicketCard(
                      product: product,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product),
                      onAdd: () => _addProduct(context, product),
                    );
                  },
                ),
    );
  }
}

class _PromoTicketCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _PromoTicketCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    const ticketBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      height: 135,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: InkWell(
          onTap: onTap,
          borderRadius: ticketBorderRadius,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [EsquemaColor.card, EsquemaColor.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: EsquemaColor.line.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left Part - Image & Discount
                Container(
                  width: 110,
                  height: double.infinity,
                  color: EsquemaColor.chip,
                  child: Stack(
                    children: [
                      product.imageUrl == null || product.imageUrl!.isEmpty
                          ? const Center(child: Icon(Icons.restaurant, size: 36, color: EsquemaColor.muted))
                          : Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.restaurant, size: 36)),
                            ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EsquemaColor.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.discountPercent}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Middle Part - Dotted Line
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _DashedLinePainter(),
                ),

                // Right Part - Text & Action
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: EsquemaColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.restaurantDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EsquemaColor.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            // Prices
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.originalPrice != null)
                                  Text(
                                    '\$${product.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: EsquemaColor.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: EsquemaColor.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EsquemaColor.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: product.stock <= 0 ? null : onAdd,
                              child: const Text(
                                'Obtener',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Clipper for Ticket cut-out edges on the sides
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 10.0;
    
    // Start at top left
    path.moveTo(0, 0);
    
    // Top line
    path.lineTo(size.width, 0);
    
    // Right side cut-out center
    path.lineTo(size.width, size.height / 2 - radius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    
    // Bottom line
    path.lineTo(0, size.height);
    
    // Left side cut-out center
    path.lineTo(0, size.height / 2 + radius);
    path.arcToPoint(
      Offset(0, size.height / 2 - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Painter for drawing dotted vertical line
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EsquemaColor.line.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 8.0; // padding top
    
    while (startY < 135 - 8) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
