import 'dart:io';
import 'package:flutter/material.dart';
import 'package:senemarket/views/product_view/product_detail_page.dart'; // Asegúrate de que la ruta sea la correcta

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  /// Callback que notifica cuando se hace clic en el producto.
  final ValueChanged<String>? onCategoryTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = product['category'] ?? '';

    return GestureDetector(
      onTap: () {
        // Dispara el callback para contar el click en la categoría.
        if (onCategoryTap != null && category is String && category.isNotEmpty) {
          onCategoryTap!(category);
        }
        // Navega a la pantalla de detalle del producto.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: product['image'] != null
                    ? Image.file(
                  File(product['image']),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Texto
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$${product['price'] ?? "0.00"}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['name'] ?? "No Name",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
