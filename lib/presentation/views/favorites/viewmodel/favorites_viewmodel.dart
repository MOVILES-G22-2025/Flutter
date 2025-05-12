// lib/presentation/views/favorites/viewmodel/favorites_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/favorites_repository.dart';
import '../../../../data/local/database/database_helper.dart';

class FavoritesViewModel extends ChangeNotifier {
  final FavoritesRepository _repo;
  final _db = DatabaseHelper();
  final _auth = FirebaseAuth.instance;

  FavoritesViewModel(this._repo);

  List<Product> _favorites = [];
  List<Product> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showRecentFirst = true;
  bool get showRecentFirst => _showRecentFirst;

  void toggleOrder() {
    _showRecentFirst = !_showRecentFirst;
    _favorites = _favorites.reversed.toList();
    notifyListeners();
  }

  /// Carga en ONLINE u OFFLINE según conexión
  Future<void> loadFavorites({bool forceRemote = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _favorites = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    // lee online si pedimos o estamos conectados, sino offline
    final online = forceRemote || await _repo.connectivity.isOnline$.first;
    if (online) {
      // delega en el repo (que actualiza cached_products)
      _favorites = await _repo.fetchFavorites(userId: user.uid, forceRemote: true);
    } else {
      // leo directamente de cached_products
      final rows = await _db.getCachedFavorites(user.uid);
      _favorites = rows.map((r) {
        final favList = (jsonDecode(r['favoritedBy'] as String) as List).cast<String>();
        final urls    = (r['imageUrls'] as String).split(',');
        final tsInt   = r['timestamp'] as int?;
        return Product(
          id:          r['id'] as String,
          name:        r['name'] as String,
          description: r['description'] as String,
          category:    r['category'] as String,
          price:       r['price'] as double,
          imageUrls:   urls,
          sellerName:  r['sellerName'] as String,
          favoritedBy: favList,
          timestamp:   tsInt!=null ? DateTime.fromMillisecondsSinceEpoch(tsInt) : null,
          userId:      r['userId'] as String,
        );
      }).toList();
    }

    if (!_showRecentFirst) _favorites = _favorites.reversed.toList();
    _isLoading = false;
    notifyListeners();
  }

  /// Toggle favorito offline‐first: actualiza cached_products y luego encola/remote
  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final isFav = _favorites.any((p) => p.id == product.id);

    if (isFav) {
      await _repo.removeProductFromFavorites(user.uid, product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      await _repo.addProductToFavorites(user.uid, product.id);
      _favorites.add(product);
    }

    notifyListeners();
  }
}
