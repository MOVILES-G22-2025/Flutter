// lib/data/datasources/local/services/sync_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/product_repository.dart';

class SyncService {
  // Instancia del repositorio que maneja SQLite
  final ProductRepository _productoRepo = ProductRepository();

  /// Verifica la conectividad y, si hay Internet,
  /// lanza una sincronización puntual desde Firebase a SQLite.
  Future<void> verificarConectividadYSincronizar() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("No hay conexión a internet. Usando datos locales.");
    } else {
      print("Conectado a internet. Sincronizando productos...");
      await _productoRepo.sincronizarProductosConFirebase();
    }
  }

  /// Escucha en tiempo real los cambios en la colección 'productos' de Firestore
  /// y aplica cada adición, modificación o eliminación a la base local.
  void escucharCambiosEnFirebase() {
    FirebaseFirestore.instance
        .collection('productos')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data()!;
        // Prepara el mapa con los datos transformados para SQLite
        final productoMap = <String, dynamic>{
          'id': change.doc.id,                     // Usa el ID de Firestore
          'category': data['category'],
          'description': data['description'],
          'imageUrls': (data['imageUrls'] as List).join(','),
          'name': data['name'],
          'price': data['price'],
          'sellerName': data['sellerName'],
          'timestamp': data['timestamp'],
          'userId': data['userId'],
        };

        switch (change.type) {
          case DocumentChangeType.added:
            _productoRepo.insertProducto(productoMap);
            break;
          case DocumentChangeType.modified:
            _productoRepo.updateProducto(productoMap);
            break;
          case DocumentChangeType.removed:
            _productoRepo.deleteProducto(change.doc.id);
            break;
        }
      }
    }, onError: (e) {
      print('Error al escuchar cambios de Firebase: $e');
    });
  }
}
