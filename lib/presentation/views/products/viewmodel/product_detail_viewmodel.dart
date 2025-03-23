import 'package:flutter/material.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ViewModel for managing the favorite state of a single product.
/// Connects product detail view with the domain repositories.
class ProductDetailViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;
  final UserRepository _userRepository;
  final FirebaseAuth _auth;

  bool isFavorite = false;
  bool isLoading = false;

  ProductDetailViewModel(
      this._favoritesRepository,
      this._userRepository, {
        FirebaseAuth? auth,
      }) : _auth = auth ?? FirebaseAuth.instance;

  /// Loads the current favorite status for the given product
  /// by checking the user's favorite list in Firestore.
  Future<void> init(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userData = await _userRepository.getUserData();
    final favorites = userData?['favorites'] ?? [];

    isFavorite = favorites.contains(product.id);
    notifyListeners(); // Updates UI to reflect favorite state
  }

  /// Toggles favorite state and syncs with Firestore.
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners(); // Show loading animation if needed

    try {
      if (isFavorite) {
        await _favoritesRepository.removeProductFromFavorites(user.uid, product.id);
      } else {
        await _favoritesRepository.addProductToFavorites(user.uid, product.id);
      }

      isFavorite = !isFavorite;
    } catch (e) {
      // In production, use Logger instead of print
      print('Error toggling favorite: $e');
    }

    isLoading = false;
    notifyListeners(); // Update UI
  }
}
