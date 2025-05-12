// lib/presentation/views/cart/cart_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/presentation/views/cart/viewmodel/cart_viewmodel.dart';
import '../../../../data/local/models/cart_item.dart';
import '../../../../domain/entities/product.dart';
import '../../../../core/services/custom_cache_manager.dart';
import '../products/product_detail_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        title: const Text('My shopping cart',
            style: TextStyle(
              fontFamily: 'Cabin',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            )),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your shopping cart is empty',
        style: TextStyle(
        fontFamily: 'Cabin',
        fontSize: 18,
        color: Colors.grey,
      ),))
          : Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) => _CartRow(item: cart.items[i]),
            ),
          ),
          const _CartSummary(),
        ],
      ),
    );
  }
}

/// Miniatura cacheada (offline-first).
Widget _buildThumbnail(String url) {
  return CachedNetworkImage(
    imageUrl: url,
    cacheManager: CustomCacheManager.instance,
    width: 64,
    height: 64,
    fit: BoxFit.cover,
    placeholder: (_, __) => Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (_, __, ___) => Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    ),
  );
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CartViewModel>();

    // Construimos un Product mínimo para pasar al detalle
    final product = Product(
      id: item.productId,
      name: item.name,
      description: '',
      category: '',
      price: item.price,
      imageUrls: [item.imageUrl],
      sellerName: '',
      favoritedBy: [], userId: '',
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navega al detalle
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product, originIndex: 0,),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildThumbnail(item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontFamily: 'Cabin', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => vm.removeOne(item.productId),
            ),
            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => vm.addProductByDetails(
                productId: item.productId,
                name: item.name,
                price: item.price,
                imageUrl: item.imageUrl,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(
                      "Remove item",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    content: const Text(
                      "Are you sure you want to remove this item from your cart?",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            color: constants.AppColors.primary30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await vm.removeItem(item.productId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item removed')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartViewModel>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total (${vm.totalItems} items): \$${vm.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontFamily: 'Cabin', fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout not implemented yet')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: constants.AppColors.primary30,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                  fontFamily: 'Cabin', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
