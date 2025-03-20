import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/views/product_view/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final ValueChanged<String>? onCategoryTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = product['category'] ?? '';
    final productName = product['name'] ?? "Sin nombre";
    final productPrice = product['price'] ?? "0.00";
    final imageUrl =
        (product['imageUrls'] is List && product['imageUrls'].isNotEmpty)
            ? product['imageUrls'][0]
            : null;

    return GestureDetector(
      onTap: () {
        if (onCategoryTap != null &&
            category is String &&
            category.isNotEmpty) {
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
        color: AppColors.primary50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl != null
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

            // Nombre del producto en la parte superior
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productName,
                style: const TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Precio en la parte inferior
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "\$ $productPrice",
                style: const TextStyle(
                  fontFamily: 'Cabin',
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
