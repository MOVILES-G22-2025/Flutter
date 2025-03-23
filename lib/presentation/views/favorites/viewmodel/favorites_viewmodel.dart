import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:senemarket/domain/entities/product.dart';

import '../../../../data/models/product_dto.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Product> _favorites = [];
  List<Product> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
      final favoriteIds = List<String>.from(userDoc.data()?['favorites'] ?? []).reversed.toList();

      final favoriteDocs = await Future.wait(
        favoriteIds.map((id) => _firestore.collection('products').doc(id).get()),
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
