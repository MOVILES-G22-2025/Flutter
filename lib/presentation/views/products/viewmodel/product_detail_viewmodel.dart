import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final UserRepository _userRepository;
  final FirebaseAuth _auth;

  bool isFavorite = false;
  bool isLoading = false;

  ProductDetailViewModel(
      this._productRepository,
      this._userRepository, {
        FirebaseAuth? auth,
      }) : _auth = auth ?? FirebaseAuth.instance;

  Future<void> init(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userData = await _userRepository.getUserData();
    final favorites = userData?['favorites'] ?? [];

    isFavorite = favorites.contains(product.id);
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      if (isFavorite) {
        await _productRepository.removeProductFavorite(
          userId: user.uid,
          productId: product.id,
        );
      } else {
        await _productRepository.addProductFavorite(
          userId: user.uid,
          productId: product.id,
        );
      }
      isFavorite = !isFavorite;
    } catch (e) {
      print('Error toggling favorite: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}