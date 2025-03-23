import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senemarket/domain/entities/product.dart';
import '../../../../data/models/product_dto.dart';

/// ViewModel that manages the list of favorite products
/// for the current authenticated user.
class FavoritesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Product> _favorites = [];
  List<Product> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showRecentFirst = true;
  bool get showRecentFirst => _showRecentFirst;

  /// Changes the display order of favorites (recent ↔ oldest).
  void toggleOrder() {
    _showRecentFirst = !_showRecentFirst;
    _favorites = _favorites.reversed.toList();
    notifyListeners();
  }

  /// Loads the current user's favorite products from Firestore.
  /// If the user is not logged in, returns an empty list.
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _favorites = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final favoriteIds = List<String>.from(userDoc.data()?['favorites'] ?? []);
      final orderedIds = _showRecentFirst ? favoriteIds.reversed.toList() : favoriteIds;

      // Fetch each product document based on its ID
      final favoriteDocs = await Future.wait(
        orderedIds.map((id) => _firestore.collection('products').doc(id).get()),
      );

      _favorites = favoriteDocs
          .where((doc) => doc.exists)
          .map((doc) => ProductDTO.fromDocumentSnapshot(doc).toDomain())
          .toList();
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
