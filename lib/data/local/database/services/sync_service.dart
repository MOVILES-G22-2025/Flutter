// lib/data/datasources/local/services/sync_service.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/product_repository.dart';

class SyncService {
  /// Instancia del repositorio que maneja SQLite
  final ProductRepository _productRepo = ProductRepository();

  /// Verifica la conectividad y, si hay Internet,
  /// lanza una sincronización puntual desde Firebase a SQLite.
  Future<void> verificarConectividadYSincronizar() async {
    print('🔍 Verificando conectividad...');
    var connectivityResult = await Connectivity().checkConnectivity();
    print('📶 Estado de conexión: $connectivityResult');
    if (connectivityResult == ConnectivityResult.none) {
      print('🚫 No hay conexión a internet. Usando datos locales.');
    } else {
      print('✅ Conectado a internet. Iniciando sincronización puntual...');
      await _productRepo.sincronizarProductsConFirebase();
      print('✅ Sincronización puntual finalizada.');
    }
  }

  /// Escucha en tiempo real los cambios en la colección 'products' de Firestore
  /// y aplica cada adición, modificación o eliminación a la base local.
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
          'id': change.doc.id,
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
            print('➕ Document added: id=${change.doc.id}');
            _productRepo.insertProduct(productMap);
            print('   ✅ Insertado localmente: ${data['name']}');
            break;
          case DocumentChangeType.modified:
            print('✏️ Document modified: id=${change.doc.id}');
            _productRepo.updateProduct(productMap);
            print('   🔄 Actualizado localmente: ${data['name']}');
            break;
          case DocumentChangeType.removed:
            print('🗑️ Document removed: id=${change.doc.id}');
            _productRepo.deleteProduct(change.doc.id);
            print('   ✅ Eliminado localmente: id=${change.doc.id}');
            break;
        }
      }
    }, onError: (e) {
      print('❌ Error al escuchar cambios de Firebase: $e');
    });
  }
}
