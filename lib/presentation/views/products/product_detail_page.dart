import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:senemarket/constants.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/products/widgets/product_image_carousel.dart';
import '../../widgets/global/navigation_bar.dart';

/// This page shows detailed information about a selected product.
class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isStarred = false;
  int _selectedIndex = 0;

  final _productRepo = ProductRepositoryImpl();
  final _userRepo = UserRepositoryImpl();

  String get productId => widget.product.id;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited(); // Check if the product is in the user's favorites list
  }

  /// Checks Firestore to know if the current product is a favorite.
  Future<void> _checkIfFavorited() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || productId.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        List<dynamic> favorites = data?['favorites'] ?? [];
        setState(() {
          _isStarred = favorites.contains(productId);
        });
      }
    } catch (e) {
      print("Error checking favorites: $e");
    }
  }

  /// Adds or removes the product from user's favorites.
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
    } catch (e) {
      print("Error updating favorite: $e");
    }
  }

  /// Handles navigation bar interaction at the bottom of the page.
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add_product');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.product.imageUrls;

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            widget.product.name,
            style: const TextStyle(
              fontFamily: 'Cabin',
              color: Colors.black,
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            ProductImageCarousel(images: images),

            /// Product price + favorite button
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$ ${widget.product.price.toStringAsFixed(2)}",
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

            /// Show publish date if available
            if (widget.product.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Posted: ${DateFormat.yMMMMd().format(widget.product.timestamp!)}',
                    style: const TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            /// Category info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  child: Text(
                    widget.product.category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cabin',
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            /// Buy & Cart buttons
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

            /// Seller info
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
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
                        Text(
                          widget.product.sellerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Cabin', fontSize: 20),
                        ),
                      ],
                    ),
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

            /// Description
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
                    widget.product.description,
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
