// lib/presentation/views/product_view/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/common/navigation_bar.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/presentation/widgets/product_image_carousel.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isStarred = false;
  int _selectedIndex = 0;

  // En un futuro, usa Provider para inyectar repos
  // Pero aquí, para ejemplo rápido:
  final _productRepo = ProductRepositoryImpl();
  final _userRepo = UserRepositoryImpl();

  String get productId => widget.product['id'] ?? '';

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || productId.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        List<dynamic> favorites = data['favorites'] ?? [];
        setState(() {
          _isStarred = favorites.contains(productId);
        });
      }
    } catch (e) {
      print("Error checking favorites: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || productId.isEmpty) {
      print("User not authenticated or productId empty.");
      return;
    }

    setState(() {
      _isStarred = !_isStarred;
    });

    try {
      if (_isStarred) {
        await _userRepo.addFavorite(productId);
        await _productRepo.addProductFavorite(userId: userId, productId: productId);
      } else {
        await _userRepo.removeFavorite(productId);
        await _productRepo.removeProductFavorite(userId: userId, productId: productId);
      }
      print("Favorites updated successfully.");
    } catch (e) {
      print("Error updating favorite: $e");
    }
  }

  Future<String> _getSellerName() async {
    return widget.product['sellerName'] ?? "Unknown Seller";
  }

  @override
  Widget build(BuildContext context) {
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
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            ProductImageCarousel(images: images),
            Padding(
              padding: const EdgeInsets.only(right: 10),
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
            Row(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {},
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
                    onPressed: () {},
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
            Padding(
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
                              style: TextStyle(fontFamily: 'Cabin', fontSize: 20),
                            );
                          } else if (snapshot.hasError) {
                            return const Text(
                              "Unknown Seller",
                              style: TextStyle(fontFamily: 'Cabin', fontSize: 20),
                            );
                          } else {
                            return Text(
                              snapshot.data ?? "Unknown Seller",
                              style: const TextStyle(fontFamily: 'Cabin', fontSize: 20),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
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
    );
  }
}
