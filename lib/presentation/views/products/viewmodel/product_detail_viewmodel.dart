// lib/presentation/views/products/viewmodel/product_detail_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../data/local/database/database_helper.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';
import '../../../../domain/repositories/user_repository.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final UserRepository _userRepository;
  final FirebaseAuth _auth;
  final _db = DatabaseHelper();

  bool isFavorite = false;
  bool isClickLoading = false;
  int clickCount = 0;

  ProductDetailViewModel(
      this._productRepository,
      this._userRepository, {
        FirebaseAuth? auth,
      }) : _auth = auth ?? FirebaseAuth.instance;

  /// Inicializa estado de favorito leyendo siempre la tabla local
  Future<void> init(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1) Intentamos leer de la tabla cached_products
    final rows = await _db.database.then((db) => db.query(
      'cached_products',
      columns: ['favoritedBy'],
      where: 'id = ?',
      whereArgs: [product.id],
    ));
    if (rows.isNotEmpty) {
      final favList = (jsonDecode(rows.first['favoritedBy'] as String) as List).cast<String>();
      isFavorite = favList.contains(user.uid);
    } else {
      isFavorite = false;
    }

    notifyListeners();
  }

  Future<void> recordAndFetchClicks(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isClickLoading = true;
    notifyListeners();

    await _productRepository.logProductClick(user.uid, productId);
    clickCount = await _productRepository.fetchProductClickCount(productId);

    isClickLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1) Actualizo remoto/cola y local (cached_products) a través del repo:
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

    // 2) Cambio estado UI y notifico
    isFavorite = !isFavorite;
    notifyListeners();
  }
}
