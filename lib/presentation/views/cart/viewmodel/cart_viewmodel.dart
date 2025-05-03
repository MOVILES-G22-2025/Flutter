import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../data/local/models/cart_item.dart';

class CartViewModel extends ChangeNotifier {
  /// Caja Hive — ya está abierta en main.dart
  final Box<CartItem> _box = Hive.box<CartItem>('cart');

  /// Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Suscripción a cambios de autenticación
  late final StreamSubscription<User?> _authSub;

  /// UID del usuario actual
  String? _uid;

  /// Indicador de sincronización
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  CartViewModel() {
    // Escucha cambios en el estado de autenticación
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
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
    await _syncFromRemote();

    _isLoading = false;
    notifyListeners();
  }

  /// Sincroniza Firestore -> Hive
  Future<void> _syncFromRemote() async {
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
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        imageUrl: data['imageUrl'] as String? ?? '',
      );
      await _box.put(item.productId, item);
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
        ),
      );
    }
    notifyListeners();

    // Sincronizar con Firestore
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('cartItems')
        .doc(productId);

    await docRef.set({
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': FieldValue.increment(1),
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Resta una unidad; si queda en cero, elimina el ítem
  Future<void> removeOne(String productId) async {
    final existing = _box.get(productId);
    if (existing == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('cartItems')
        .doc(productId);

    if (existing.quantity > 1) {
      existing.quantity--;
      await existing.save();
      await docRef.update({'quantity': FieldValue.increment(-1)});
    } else {
      await removeItem(productId);
      return;
    }

    notifyListeners();
  }

  /// Elimina completamente el ítem
  Future<void> removeItem(String productId) async {
    await _box.delete(productId);
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('cartItems')
        .doc(productId)
        .delete();
  }

  /// Limpia todo el carrito (local y remoto)
  Future<void> clearCart() async {
    // Local
    await _box.clear();
    notifyListeners();

    // Remoto
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
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}