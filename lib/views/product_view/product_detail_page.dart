import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Obtiene el ID del producto (asegúrate de que 'id' exista en tu product)
  String get productId => widget.product['ID'] ?? '';


  // Actualiza el índice seleccionado de la barra de navegación.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Función que consulta Firestore para obtener el nombre del vendedor a partir de su id.
  Future<String> _getSellerName() async {
    return widget.product['sellerName'] ?? "Unknown Seller";
  }

  // Consulta si el producto ya está en favotitos del usuario.
  Future<void> _checkIfFavorited() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final productId = widget.product['id'] ?? "";
    print("Checking favorites for productId: $productId, userId: $userId");

    if (userId == null || productId.isEmpty) {
      print("User not authenticated or productId empty.");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> favorites = data['favorites'] ?? [];
        print("Favorites in user doc: $favorites");
        setState(() {
          _isStarred = favorites.contains(productId);
          print("Favorite status set to: $_isStarred");
        });
      }
    } catch (e) {
      print("Error checking favorites: $e");
    }
  }


  // - Añade/Elimina el producto y el usuario
  Future<void> _toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final productId = widget.product['id'] ?? "";


    if (userId == null || productId.isEmpty) {
      print("User not authenticated or productId empty.");
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final productDocRef = FirebaseFirestore.instance.collection('products').doc(productId);

    // Cambia el estado local para actualizar la UI.
    setState(() {
      _isStarred = !_isStarred;
    });

    try {
      if (_isStarred) {
        await userDocRef.set({
          'favorites': FieldValue.arrayUnion([productId])
        }, SetOptions(merge: true));

        await productDocRef.set({
          'favoritedBy': FieldValue.arrayUnion([userId])
        }, SetOptions(merge: true));
      } else {
        await userDocRef.set({
          'favorites': FieldValue.arrayRemove([productId])
        }, SetOptions(merge: true));

        await productDocRef.set({
          'favoritedBy': FieldValue.arrayRemove([userId])
        }, SetOptions(merge: true));
      }
      print("Favorites updated successfully.");
    } catch (e) {
      print("Error updating favorite: $e");
    }
  }


  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  @override
  Widget build(BuildContext context) {
    // Lista de imágenes del producto

    final List<String> images =
        (widget.product['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: Text(
          widget.product['name'] ?? "Sin Nombre",

          style: const TextStyle(
            fontFamily: 'Cabin',
            color: Colors.black,
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [

              // Carrusel de imágenes

              Container(
                padding: const EdgeInsets.only(top: 8, right: 15, bottom: 5),
                width: MediaQuery.of(context).size.width,
                height: 350,
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

              // Contenedor con precio y botón de favoritos


              Container(
                padding: const EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$ ${widget.product['price'] ?? "0"}",
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
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
              ),
              // Categoría
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
                      widget.product['category'] ?? "No category",
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


              // Botones "Buy Now" y "Add to cart"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Buy Now"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary30,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Buy now',
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Add to cart"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary20,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info del vendedor

              Container(
                padding: const EdgeInsets.only(top: 8, bottom: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre del vendedor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sold by",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                        FutureBuilder<String>(
                          future: _getSellerName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
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
                    // Botón para hablar con el vendedor
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Talk with the seller"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary20,
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Talk with the seller',
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 15,
                          color: AppColors.primary0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Descripción
              Container(
                padding: const EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description ",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.product['description'] ?? "No description available",
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
