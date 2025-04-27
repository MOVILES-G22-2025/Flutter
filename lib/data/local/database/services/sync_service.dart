// lib/data/datasources/local/services/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/product_repository.dart';

class SyncService {
  final ProductRepository _productRepo = ProductRepository();

  Future<void> verificarConectividadYSincronizar() async { /* …sin cambios… */ }

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
          'id'        : change.doc.id,
          'category'  : data['category'],
          'description': data['description'],
          'imageUrls' : (data['imageUrls'] as List).join(','),
          'name'      : data['name'],
          'price'     : data['price'],
          'sellerName': data['sellerName'],

          // 🔹 Conversión Timestamp → int (milisegundos)
          'timestamp' : data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : data['timestamp'],

          'userId'    : data['userId'],
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
}
