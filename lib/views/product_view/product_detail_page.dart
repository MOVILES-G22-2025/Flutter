import 'dart:io';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Detalle del Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            if (product['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(product['image']),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 16),
            // Nombre del producto
            Text(
              product['name'] ?? 'No Name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Precio del producto
            Text(
              "\$${product['price'] ?? '0.00'}",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Categoría del producto
            if (product['category'] != null)
              Row(
                children: [
                  const Icon(Icons.category, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    product['category'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Descripción del producto
            Text(
              product['description'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16),
            ),
            // Puedes agregar más detalles según necesites
          ],
        ),
      ),
    );
  }
}
