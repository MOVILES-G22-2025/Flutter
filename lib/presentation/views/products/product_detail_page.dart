import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_detail_viewmodel.dart';
import 'package:senemarket/presentation/views/products/widgets/product_image_carousel.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import '../../../domain/repositories/product_repository.dart';
import '../cart/viewmodel/cart_viewmodel.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final int originIndex;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.originIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ── we now also kick off our click‐counter right after init() ──
      create: (_) {
        final vm = ProductDetailViewModel(
          context.read<ProductRepository>(),
          context.read<UserRepository>(),
          auth: FirebaseAuth.instance,
        );
        vm.init(product);
        vm.recordAndFetchClicks(product.id);
        return vm;
      },
      child: ProductDetailPageContent(
          product: product,
          originIndex: originIndex,
      ),
    );
  }
}

class ProductDetailPageContent extends StatelessWidget {
  final Product product;
  final int originIndex;

  const ProductDetailPageContent({
    Key? key,
    required this.product,
    required this.originIndex,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductDetailViewModel>();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            product.name,
            style: const TextStyle(
              fontFamily: 'Cabin',
              color: Colors.black,
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImageCarousel(images: product.imageUrls),
            const SizedBox(height: 10),

            // ── Price + favorite ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$ ${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontFamily: 'Cabin',
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    vm.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.primary30,
                    size: 32,
                  ),
                  onPressed: () => vm.toggleFavorite(product),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Click‐counter ──
            Row(
              children: [
                const Icon(Icons.remove_red_eye, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                vm.isClickLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  '${vm.clickCount} views',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            // ── Posted date ──
            if (product.timestamp != null)
              Text(
                'Posted: ${DateFormat.yMMMMd().format(product.timestamp!)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

            const SizedBox(height: 16),

            // ── Category ──
            Row(
              children: [
                const Text(
                  "Category: ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Cabin',
                  ),
                ),
                Expanded(
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Cabin',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Sold by + Chat ──
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sold by",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.sellerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Cabin',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      // Asegurarnos de tener UID y sellerId
                      if (currentUserId != null && product.userId.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'receiverId': product.userId,
                            'receiverName': product.sellerName,
                          },
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text("Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary20,
                      foregroundColor: AppColors.primary0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ──
            const Text(
              "Description",
              style: TextStyle(
                fontFamily: 'Cabin',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              product.description,
              style: const TextStyle(
                fontFamily: 'Cabin',
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),
            // ── Acciones: Añadir al carrito + Comprar ──
            Row(
              children: [
                // Botón “Add to cart”
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // añadimos al carrito usando los detalles mínimos
                      context.read<CartViewModel>().addProductByDetails(
                        productId: product.id,
                        name: product.name,
                        price: product.price,
                        imageUrl: product.imageUrls.isNotEmpty
                            ? product.imageUrls.first
                            : '', // o alguna imagen por defecto
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to cart'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón “Buy now”
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: implementar checkout
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary30,
                      foregroundColor: AppColors.primary0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Buy now'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarApp(selectedIndex: originIndex),
    );
  }
}