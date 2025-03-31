import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/products/product_detail_page.dart';

/// UI card to display a single [Product].
/// Calls [onCategoryTap] when the category is tapped (optional) and [onProductTap] when the card is tapped.
class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onProductTap; // Callback opcional para el clic en el producto

  const ProductCard({
    Key? key,
    required this.product,
    this.onCategoryTap,
    this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get product details
    final category = product.category;
    final productName = product.name.isNotEmpty ? product.name : "Sin nombre";
    final productPrice = product.price;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        // Llama al callback del clic en el producto si está definido
        if (onProductTap != null) {
          onProductTap!();
        }
        // Llama al callback de categoría si se desea
        if (onCategoryTap != null && category.isNotEmpty) {
          onCategoryTap!(category);
        }
        // Navega a la página de detalle del producto
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
            // Product image
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
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
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
            // Product name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Product price
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

