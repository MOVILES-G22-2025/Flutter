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
  bool isClickLoading = false;
  int clickCount = 0;

  ProductDetailViewModel(
      this._productRepository,
      this._userRepository, {
        FirebaseAuth? auth,
      }) : _auth = auth ?? FirebaseAuth.instance;

  /// initialize favorite‐state
  Future<void> init(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userData = await _userRepository.getUserData();
    final favorites = userData?['favorites'] as List<dynamic>? ?? [];
    isFavorite = favorites.contains(product.id);
    notifyListeners();
  }

  /// Called on page‐open to log a click and then fetch total clicks
  Future<void> recordAndFetchClicks(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isClickLoading = true;
    notifyListeners();

    // 1) log click
    await _productRepository.logProductClick(user.uid, productId);

    // 2) fetch total count
    clickCount = await _productRepository.fetchProductClickCount(productId);

    isClickLoading = false;
    notifyListeners();
  }

  /// toggle favorite + update UI
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // you could show a spinner here if desired...
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }
}
