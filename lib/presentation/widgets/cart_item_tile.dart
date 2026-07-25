import 'package:flutter/material.dart';
import '../../domain/entities/cart_item.dart';
import '../../themes/esquema_color.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemTile({super.key, required this.item, required this.onIncrement, required this.onDecrement, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 76,
              height: 76,
              color: EsquemaColor.chip,
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? const Icon(Icons.fastfood, color: EsquemaColor.muted)
                  : Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary, fontSize: 16)),
                const SizedBox(height: 4),
                Text(product.description ?? 'Sin extras', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EsquemaColor.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: EsquemaColor.primary)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(color: EsquemaColor.chip, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: onDecrement, icon: Icon(item.quantity <= 1 ? Icons.delete_outline : Icons.remove, color: EsquemaColor.textPrimary), visualDensity: VisualDensity.compact),
                          Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: EsquemaColor.textPrimary)),
                          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add, color: EsquemaColor.textPrimary), visualDensity: VisualDensity.compact),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
