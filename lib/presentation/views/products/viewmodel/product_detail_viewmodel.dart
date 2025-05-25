// lib/presentation/views/products/viewmodel/product_detail_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../data/local/database/database_helper.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';
import '../../../../domain/repositories/user_repository.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductRepository _productRepo;
  final UserRepository _userRepo;
  final FirebaseAuth _auth;
  final _db = DatabaseHelper();

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  int _clickCount = 0;
  int get clickCount => _clickCount;

  bool _isClickLoading = false;
  bool get isClickLoading => _isClickLoading;

  String? _sellerImageUrl;
  String? get sellerImageUrl => _sellerImageUrl;

  ProductDetailViewModel(this._productRepo, this._userRepo, {required FirebaseAuth auth})
      : _auth = auth;

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
      _isFavorite = favList.contains(user.uid);
    } else {
      _isFavorite = false;
    }

    _clickCount = await _productRepo.getClickCount(product.id);
    _sellerImageUrl = await _userRepo.getUserProfileImage(product.userId);
    notifyListeners();
  }

  Future<void> recordAndFetchClicks(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isClickLoading = true;
    notifyListeners();

    await _productRepo.recordClick(productId);
    _clickCount = await _productRepo.getClickCount(productId);

    _isClickLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1) Actualizo remoto/cola y local (cached_products) a través del repo:
    if (_isFavorite) {
      await _productRepo.removeFromFavorites(product.id);
    } else {
      await _productRepo.addToFavorites(product.id);
    }

    // 2) Cambio estado UI y notifico
    _isFavorite = !_isFavorite;
    notifyListeners();
  }
}
