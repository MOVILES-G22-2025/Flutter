import 'dart:io';
import 'package:flutter/material.dart';
// Asegúrate de que la ruta sea la correcta
import '../product-detail_view/product-detail_page.dart';


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
        // Si tienes un callback para la categoría, lo ejecutas
        if (onCategoryTap != null && product['category'] != null && product['category'].isNotEmpty) {
          onCategoryTap!(product['category']);
        }
        // Navegar a ProductDetailPage pasando el producto
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
              // Ejemplo dentro de un ClipRRect
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: product['imageUrl'] != null
                    ? Image.network(
                  product['imageUrl'],
                  width: 350,
                  height: 350,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 350,
                  height: 350,
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
