// lib/presentation/views/product_view/product_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/product_view/product_detail_page.dart';

/// Tarjeta para mostrar un [Product].
///
/// [onCategoryTap] se invoca cuando el usuario hace tap
/// en la tarjeta, pasando la categoría del producto.
class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<String>? onCategoryTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = product.category;
    final productName = product.name.isNotEmpty ? product.name : "Sin nombre";
    final productPrice = product.price;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        // Si deseas incrementar la categoría al hacer tap
        if (onCategoryTap != null && category.isNotEmpty) {
          onCategoryTap!(category);
        }
        // Navega a la pantalla de detalle del producto
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: (imageUrl != null)
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // Nombre
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Precio
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "\$ ${productPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
