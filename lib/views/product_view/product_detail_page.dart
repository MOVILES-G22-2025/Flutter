import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/common/navigation_bar.dart';
import '../../constants.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isStarred = false;
  int _selectedIndex = 0;

  // Función para actualizar el índice seleccionado de la barra de navegación.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Agrega aquí cualquier lógica de navegación adicional.
  }

  // Función que consulta Firestore para obtener el nombre del vendedor a partir de su id.
  Future<String> _getSellerName() async {
    final String sellerId = widget.product['userId'] ?? "";
    if (sellerId.isEmpty) return "Unknown Seller";
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? "Unknown Seller";
      } else {
        return "Unknown Seller";
      }
    } catch (e) {
      print("Error getting seller name: $e");
      return "Unknown Seller";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se asume que el campo 'imageUrls' es una lista de URLs.
    final List<String> images = (widget.product['imageUrls'] as List<dynamic>?)
        ?.cast<String>() ??
        [];

    return Scaffold(
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 50, left: 20),
          child: Column(
            children: [
              // Fila con el botón de regresar y el título del producto.
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.product['name'] ?? "Pathways 2B",
                    style: const TextStyle(
                      fontFamily: 'Cabin',
                      color: Colors.black,
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Contenedor para mostrar las imágenes en un carrusel.
              Container(
                padding:
                const EdgeInsets.only(top: 8, right: 15, bottom: 5),
                width: MediaQuery.of(context).size.width,
                height: 350, // Altura fija para el carrusel.
                child: images.isNotEmpty
                    ? PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
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
              // Contenedor con el precio y el botón de favoritos.
              Container(
                padding: const EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$ ${widget.product['price'] ?? "80.000"}",
                      style: const TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        color: Colors.black,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _isStarred = !_isStarred;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Contenedor con la categoría del producto.
              Container(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    const Text(
                      "Category: ",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.product['category'] ?? "Book",
                      style: const TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Contenedor con botones "Buy Now" y "Add to cart".
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Buy Now".
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary30,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Buy Now",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Add to cart".
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary20,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Add to cart",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenedor con la información del vendedor.
              Container(
                padding: const EdgeInsets.only(top: 8, bottom: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Columna con la información del vendedor.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sold by:",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FutureBuilder<String>(
                          future: _getSellerName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                "Loading...",
                                style: TextStyle(
                                  fontFamily: 'Cabin',
                                  fontSize: 20,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Text(
                                "Unknown Seller",
                                style: TextStyle(
                                  fontFamily: 'Cabin',
                                  fontSize: 20,
                                ),
                              );
                            } else {
                              return Text(
                                snapshot.data ?? "Unknown Seller",
                                style: const TextStyle(
                                  fontFamily: 'Cabin',
                                  fontSize: 20,
                                ),
                              );
                            }
                          },
                        ),

                      ],
                    ),
                    // Botón para "Talk with the seller".
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Talk with the seller".
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary20,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Talk with the seller",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenedor con la descripción del producto.
              Container(
                padding: const EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description: ",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.product['description'] ??
                          "No description available",
                      style: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}