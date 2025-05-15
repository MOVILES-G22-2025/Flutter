import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../data/local/models/cart_item.dart';
import '../../../../core/services/connectivity_service.dart';

class CartViewModel extends ChangeNotifier {
  /// Caja Hive — ya está abierta en main.dart
  final Box<CartItem> _box = Hive.box<CartItem>('cart');

  /// Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = ConnectivityService();

  /// Suscripción a cambios de autenticación
  late final StreamSubscription<User?> _authSub;
  late final StreamSubscription<bool> _connectivitySub;

  /// UID del usuario actual
  String? _uid;

  /// Indicador de sincronización
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  CartViewModel() {
    // Escucha cambios en el estado de autenticación
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    // Escucha cambios en la conectividad
    _connectivitySub = _connectivity.isOnline$.listen(_onConnectivityChanged);
  }

  /// Maneja cambios en la conectividad
  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && _uid != null) {
      _syncFromRemote();
    }
  }

  /// Maneja login/logout
  Future<void> _onAuthChanged(User? user) async {
    _isLoading = true;
    notifyListeners();

    if (user == null) {
      // Logout: limpiar datos locales
      await _clearLocal();
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Login: guardar UID y sincronizar
    _uid = user.uid;
    if (await _connectivity.isOnline$.first) {
      await _syncFromRemote();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sincroniza Firestore -> Hive
  Future<void> _syncFromRemote() async {
    if (_uid == null) return;
    
    try {
      // Limpia primero local para evitar datos obsoletos
      await _box.clear();

      final snap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('cartItems')
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final item = CartItem(
          productId: doc.id,
          name: data['name'] is String ? data['name'] : '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (data['quantity'] as num?)?.toInt() ?? 0,
          imageUrl: data['imageUrl'] is String ? data['imageUrl'] : '',
          description: data['description'] is String ? data['description'] : '',
          category: data['category'] is String ? data['category'] : '',
          sellerName: data['sellerName'] is String ? data['sellerName'] : '',
          userId: data['userId'] is String ? data['userId'] : '',
        );
        await _box.put(item.productId, item);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    }
  }

  /// Limpia la caja Hive
  Future<void> _clearLocal() => _box.clear();

  /// Lista de ítems
  List<CartItem> get items => _box.values.toList();

  /// Total de unidades
  int get totalItems => items.fold(0, (sum, it) => sum + it.quantity);

  /// Precio total
  double get totalPrice =>
      items.fold(0.0, (sum, it) => sum + it.price * it.quantity);

  /// Añade un producto (o incrementa)
  Future<void> addProductByDetails({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required String description,
    required String category,
    required String sellerName,
    required String sellerId,
  }) async {
    final existing = _box.get(productId);
    if (existing != null) {
      existing.quantity++;
      await existing.save();
    } else {
      await _box.put(
        productId,
        CartItem(
          productId: productId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          description: description,
          category: category,
          sellerName: sellerName,
          userId: sellerId,
        ),
      );
    }
    notifyListeners();

    // Intentar sincronizar con Firestore si hay conexión
    if (_uid != null) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(_uid)
            .collection('cartItems')
            .doc(productId);

        await docRef.set({
          'name': name,
          'price': price,
          'imageUrl': imageUrl,
          'quantity': existing?.quantity ?? 1,
          'addedAt': FieldValue.serverTimestamp(),
          'description': description,
          'category': category,
          'sellerName': sellerName,
          'userId': sellerId,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error syncing add to cart: $e');
      }
    }
  }

  /// Resta una unidad; si queda en cero, elimina el ítem
  Future<void> removeOne(String productId) async {
    final existing = _box.get(productId);
    if (existing == null) return;

    if (existing.quantity > 1) {
      existing.quantity--;
      await existing.save();
    } else {
      await removeItem(productId);
      return;
    }

    notifyListeners();

    // Intentar sincronizar con Firestore si hay conexión
    if (_uid != null) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(_uid)
            .collection('cartItems')
            .doc(productId);

        await docRef.update({
          'quantity': existing.quantity,
        });
      } catch (e) {
        debugPrint('Error syncing remove from cart: $e');
      }
    }
  }

  /// Elimina completamente el ítem
  Future<void> removeItem(String productId) async {
    await _box.delete(productId);
    notifyListeners();

    // Intentar sincronizar con Firestore si hay conexión
    if (_uid != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('cartItems')
            .doc(productId)
            .delete();
      } catch (e) {
        debugPrint('Error syncing remove item: $e');
      }
    }
  }

  /// Limpia todo el carrito (local y remoto)
  Future<void> clearCart() async {
    // Local
    await _box.clear();
    notifyListeners();

    // Intentar sincronizar con Firestore si hay conexión
    if (_uid != null) {
      try {
        final batch = _firestore.batch();
        final snap = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('cartItems')
            .get();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error syncing clear cart: $e');
      }
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _connectivitySub.cancel();
    super.dispose();
  }
}