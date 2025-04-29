import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/product_repository.dart';
import '../repositories/user_repository.dart';

class SyncService {
  final ProductRepository _productRepo = ProductRepository();
  final UserRepository _userRepo = UserRepository();

  // ---------- Sincronización de productos ----------
  Future<void> sincronizarProductos() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('products').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final productMap = _firestoreToSqliteProduct(data, doc.id);
        (await _productRepo.getProductById(doc.id)) == null
            ? await _productRepo.insertProduct(productMap)
            : await _productRepo.updateProduct(productMap);
      }
    } catch (e) {
      print('Error sincronizando productos con Firebase: $e');
    }
  }

  // ---------- Sincronización de usuarios (solo el usuario autenticado) ----------
  Future<void> sincronizarUsuarioPorEmail(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)  // Buscar solo el usuario con ese email
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final userMap = _firestoreToSqliteUser(data, doc.id);

        // Insertamos o actualizamos el usuario solo si existe
        (await _userRepo.getUserById(doc.id)) == null
            ? await _userRepo.insertUser(userMap)
            : await _userRepo.updateUser(userMap);
      } else {
        print('No se encontró el usuario con ese email');
      }
    } catch (e) {
      print('Error sincronizando usuario con Firebase: $e');
    }
  }

  // ---------- Escuchar cambios en productos en tiempo real ----------
  void escucharCambiosEnProductos() {
    print('👂 Suscribiéndose a cambios en Firestore /products');

    FirebaseFirestore.instance
        .collection('products')
        .snapshots() // Escuchar cambios en tiempo real
        .listen((snapshot) {
      print('📬 Recibido snapshot con ${snapshot.docChanges.length} cambios');

      for (var change in snapshot.docChanges) {
        final data = change.doc.data()!;

        final productMap = <String, dynamic> {
          'id'        : change.doc.id,
          'category'  : data['category'],
          'description': data['description'],
          'imageUrls' : (data['imageUrls'] as List).join(','), // lista → String
          'name'      : data['name'],
          'price'     : data['price'],
          'sellerName': data['sellerName'],
          // Conversión Timestamp → int (milisegundos)
          'timestamp' : data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : data['timestamp'],
          'userId'    : data['userId'],
        };

        switch (change.type) {
          case DocumentChangeType.added:
            print('➕ Document added: id=${change.doc.id}');
            _productRepo.insertProduct(productMap);  // Insertar nuevo producto
            break;
          case DocumentChangeType.modified:
            print('✏️ Document modified: id=${change.doc.id}');
            _productRepo.updateProduct(productMap);  // Actualizar producto existente
            break;
          case DocumentChangeType.removed:
            print('🗑️ Document removed: id=${change.doc.id}');
            _productRepo.deleteProduct(change.doc.id);  // Eliminar producto
            break;
        }
      }
    }, onError: (e) {
      print('❌ Error al escuchar cambios de Firestore: $e');
    });
  }

  // ---------- helpers para convertir los datos de Firestore a SQLite ----------
  Map<String, dynamic> _firestoreToSqliteProduct(Map<String, dynamic> data, String id) {
    return {
      'id'        : id,                                   // PK
      'category'  : data['category'],
      'description': data['description'],
      'imageUrls' : (data['imageUrls'] as List).join(','),// lista → String
      'name'      : data['name'],
      'price'     : data['price'],
      'sellerName': data['sellerName'],
      // Conversión Timestamp → int (milisegundos)
      'timestamp' : data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
          : data['timestamp'],
      'userId'    : data['userId'],
    };
  }

  Map<String, dynamic> _firestoreToSqliteUser(Map<String, dynamic> data, String id) {
    return {
      'id'       : id,                        // PK
      'name'     : data['name'],
      'career'   : data['career'],
      'semester' : data['semester'],
      'email'    : data['email'],
    };
  }
}
