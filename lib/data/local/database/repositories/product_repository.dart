import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ---------- helpers ----------

  /// Convierte un documento de Firestore en un mapa listo para SQLite
  Map<String, dynamic> _firestoreToSqlite(
      Map<String, dynamic> data, String id) {
    return {
      'id'        : id,                                   // PK
      'category'  : data['category'],
      'description': data['description'],
      'imageUrls' : (data['imageUrls'] as List).join(','),// lista → String
      'name'      : data['name'],
      'price'     : data['price'],
      'sellerName': data['sellerName'],
      // ⚠️ conversión clave -------------------------------
      'timestamp' : data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
          : data['timestamp'],  // null o ya int
      // ---------------------------------------------------
      'userId'    : data['userId'],
    };
  }

  // ---------- CRUD SQLite ----------

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await _databaseHelper.database;
    return await db.query('products');
  }

  Future<Map<String, dynamic>?> getProductById(String id) async {
    final db = await _databaseHelper.database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await _databaseHelper.database;
    await db.update('products', product,
        where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Sync Firebase → SQLite ----------

  Future<void> sincronizarProductsConFirebase() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('products').get();

      for (final doc in snapshot.docs) {
        final map = _firestoreToSqlite(doc.data(), doc.id);
        (await getProductById(doc.id)) == null
            ? await insertProduct(map)
            : await updateProduct(map);
      }
    } catch (e) {
      print('Error sincronizando productos con Firebase: $e');
    }
  }
}
