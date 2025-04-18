import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_detail_viewmodel.dart';
import 'package:senemarket/presentation/views/products/widgets/product_image_carousel.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provee el ViewModel y lo inicializa con el producto
    return ChangeNotifierProvider(
      create: (_) => ProductDetailViewModel(
        context.read<FavoritesRepository>(),
        context.read<UserRepository>(),
        auth: FirebaseAuth.instance,
      )..init(product),
      child: ProductDetailPageContent(product: product),
    );
  }
}

class ProductDetailPageContent extends StatelessWidget {
  final Product product;

  const ProductDetailPageContent({Key? key, required this.product}) : super(key: key);

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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary40,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary30,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Buy Now"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary20,
                  foregroundColor: AppColors.primary0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Add to Cart"),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImageCarousel(images: product.imageUrls),
            const SizedBox(height: 10),
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
            if (product.timestamp != null)
              Text(
                'Posted: ${DateFormat.yMMMMd().format(product.timestamp!)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 16),
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
                      // TODO: Navigate to chat
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text("Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary20,
                      foregroundColor: AppColors.primary0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}