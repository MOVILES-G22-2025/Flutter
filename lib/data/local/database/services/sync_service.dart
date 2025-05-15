// lib/data/datasources/local/services/sync_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/product_repository.dart';
import '../repositories/user_repository.dart';
import '../../../../data/repositories/user_repository_impl.dart';

class SyncService {
  final ProductRepository   _productRepo = ProductRepository();
  final UserRepositoryImpl  _userRepo    = UserRepositoryImpl();

  Future<void> verificarConectividadYSincronizar() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn != ConnectivityResult.none) {
      await _userRepo.syncPendingUsers();

      // ── 2) Pull: refrescar el usuario autenticado ──
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await sincronizarUsuarioPorEmail(user.email!);
      }

      // ── 3) Tu sincronización de productos (igual que antes) ──
      final snapshot =
      await FirebaseFirestore.instance.collection('products').get();
      for (final doc in snapshot.docs) {
        final data       = doc.data();
        final productMap = _firestoreToSqliteProduct(data, doc.id);

        final exists = await _productRepo.getProductById(doc.id);
        if (exists == null) {
          await _productRepo.insertProduct(productMap);
        } else {
          await _productRepo.updateProduct(productMap);
        }
      }
    } else {
      print('⚠️  Sin conexión: sólo datos locales');
    }
  }

  /// Escucha cambios en /products (idéntico a tu original).
  void escucharCambiosEnFirebase() {
    print('👂 Suscribiéndose a cambios en Firestore /products');
    FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      print('📬 Recibido snapshot con ${snapshot.docChanges.length} cambios');
      for (var change in snapshot.docChanges) {
        final data = change.doc.data()!;
        final productMap = <String, dynamic>{
          'id'         : change.doc.id,
          'category'   : data['category'],
          'description': data['description'],
          'imageUrls'  : (data['imageUrls'] as List).join(','),
          'name'       : data['name'],
          'price'      : data['price'],
          'sellerName' : data['sellerName'],
          'timestamp'  : data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : data['timestamp'],
          'userId'     : data['userId'],
        };

        switch (change.type) {
          case DocumentChangeType.added:
            print('➕ Document added: id=${change.doc.id}');
            _productRepo.insertProduct(productMap);
            break;
          case DocumentChangeType.modified:
            print('✏️ Document modified: id=${change.doc.id}');
            _productRepo.updateProduct(productMap);
            break;
          case DocumentChangeType.removed:
            print('🗑️ Document removed: id=${change.doc.id}');
            _productRepo.deleteProduct(change.doc.id);
            break;
        }
      }
    }, onError: (e) {
      print('❌ Error al escuchar cambios de Firebase: $e');
    });
  }

  // —— Helpers de conversión —— //

  Map<String, dynamic> _firestoreToSqliteProduct(
      Map<String, dynamic> data, String id) {
    return {
      'id'         : id,
      'category'   : data['category'],
      'description': data['description'],
      'imageUrls'  : (data['imageUrls'] as List).join(','),
      'name'       : data['name'],
      'price'      : data['price'],
      'sellerName' : data['sellerName'],
      'timestamp'  : data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
          : data['timestamp'],
      'userId'     : data['userId'],
    };
  }

  /// Convierte el documento Firestore→mapa SQLite para usuarios.
  Future<void> sincronizarUsuarioPorEmail(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc     = snapshot.docs.first;
        final userMap = _firestoreToSqliteUser(doc.data(), doc.id);

        final exists = await _userRepo.getUserById(doc.id);
        if (exists == null) {
          await _userRepo.insertUser(userMap);
        } else {
          await _userRepo.updateUser(userMap);
        }
      } else {
        print('No se encontró el usuario con el email $email');
      }
    } catch (e) {
      print('Error sincronizando usuario con Firebase: $e');
    }
  }

  Map<String, dynamic> _firestoreToSqliteUser(
      Map<String, dynamic> data, String id) {
    return {
      'id'       : id,
      'name'     : data['name'],
      'career'   : data['career'],
      'semester' : data['semester'],
      'email'    : data['email'],
    };
  }


  StreamSubscription<ConnectivityResult>? _connSub;

  /// Llama inicialmente y luego a cada cambio de conectividad
  void start() {
    // Primer intento
    verificarConectividadYSincronizar();

    // Escuchar cambios
    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((status) {
      if (status != ConnectivityResult.none) {
        verificarConectividadYSincronizar();
      }
    });
  }

  /// Para liberar la suscripción cuando cierres sesión o la app termine
  void dispose() {
    _connSub?.cancel();
  }
}
