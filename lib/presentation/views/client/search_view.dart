import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product.dart';
import '../../../themes/esquema_color.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_title.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _search = TextEditingController();
  final List<String> _localHistory = [];
  bool _initialized = false;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    _search.text = arg?.toString() ?? '';
    _initialized = true;
    Future.microtask(() => context.read<ProductViewModel>().loadProducts(search: _search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final trimmed = query.trim();
      context.read<ProductViewModel>().loadProducts(search: trimmed);
    });
  }

  void _submit() {
    final query = _search.text.trim();
    if (query.isNotEmpty && !_localHistory.contains(query)) {
      setState(() => _localHistory.insert(0, query));
    }
    context.read<ProductViewModel>().loadProducts(search: query);
  }

  void _searchTerm(String value) {
    _search.text = value;
    _submit();
  }

  void _add(Product product) {
    final ok = context.read<CartViewModel>().add(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '${product.name} agregado' : 'Solo puedes comprar de un local por pedido.')));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final products = vm.products;
    final categories = vm.categories;
    final promos = vm.discountedProducts.take(1).toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Locales, platos y productos',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () { _search.clear(); _submit(); }),
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.cart), icon: const Icon(Icons.shopping_cart_outlined)),
              Consumer<CartViewModel>(
                builder: (context, cart, _) => cart.count == 0 
                  ? const SizedBox.shrink() 
                  : Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: EsquemaColor.primary, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('${cart.count}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          if (_localHistory.isNotEmpty) ...[
            const Text('Tus últimas búsquedas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: EsquemaColor.dark)),
            const SizedBox(height: 10),
            ..._localHistory.take(5).map((query) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: EsquemaColor.chip, child: Icon(Icons.history, color: EsquemaColor.dark)),
                  title: Text(query),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _localHistory.remove(query))),
                  onTap: () => _searchTerm(query),
                )),
            const SizedBox(height: 18),
          ],
          if (promos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: EsquemaColor.success, borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                Expanded(child: Text('${promos.first.discountPercent}% OFF en ${promos.first.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                const Icon(Icons.local_offer_rounded, color: Colors.white, size: 50),
              ]),
            ),
          ],
          if (categories.isNotEmpty) ...[
            const SectionTitle(title: 'Búsquedas que son tendencia'),
            ...categories.asMap().entries.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: EsquemaColor.line), borderRadius: BorderRadius.circular(16)), child: Text('#${entry.key + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Categoría'),
                  onTap: () => _searchTerm(entry.value),
                )),
          ],
          const SectionTitle(title: 'Resultados'),
          if (vm.loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (products.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No encontramos resultados.')))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .62),
              itemBuilder: (_, index) => ProductCard(
                product: products[index],
                onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: products[index]),
                onAdd: () => _add(products[index]),
              ),
            ),
        ],
      ),
    );
  }
}
