// lib/presentation/views/products/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/products/product_detail_page.dart';
import '../../../../core/services/custom_cache_manager.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onProductTap;
  final int originIndex;

  const ProductCard({
    Key? key,
    required this.product,
    this.onCategoryTap,
    this.onProductTap,
    required this.originIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = product.category;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        // Lógica de callback antes de navegar
        if (onProductTap != null) onProductTap!();
        if (onCategoryTap != null) onCategoryTap!(category);

        // Navegación al detalle, pasando originIndex
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              originIndex: originIndex,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheManager: CustomCacheManager.instance,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),

            // Nombre
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name.isNotEmpty ? product.name : 'Sin nombre',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Precio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '\$ ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
