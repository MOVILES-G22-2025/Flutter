import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Insertar un producto
  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'products',  // Nombre de la tabla
      product,     // Mapa con los datos del producto
      conflictAlgorithm: ConflictAlgorithm.replace,  // Si hay conflicto, reemplaza el dato
    );
  }

  // Obtener todos los productos
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await _databaseHelper.database;
    return await db.query('products');  // Realiza un SELECT de todos los productos
  }

  // Obtener un producto por su ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;  // Retorna el producto encontrado
  }

  // Actualizar un producto
  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await _databaseHelper.database;
    await db.update(
      'products',
      product,  // Mapa con los datos a actualizar
      where: 'id = ?',  // Condición para encontrar el producto
      whereArgs: [product['id']],
    );
  }

  // Eliminar un producto
  Future<void> deleteProduct(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',  // Condición para eliminar el producto por ID
      whereArgs: [id],
    );
  }

  // Realizar una transacción (Ejemplo: insertar y actualizar productos)
  Future<void> realizarTransaccion() async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Insertar un nuevo producto
      await txn.insert(
        'products',
        {'name': 'Product 2', 'price': 30.00},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Actualizar otro producto
      await txn.update(
        'products',
        {'name': 'Producto actualizado', 'price': 35.00},
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  // Sincronizar productos con Firebase
  // Dentro de la clase ProductRepository
  Future<void> sincronizarProductsConFirebase() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('productos').get();

      for (var doc in snapshot.docs) {
        var productData = doc.data();
        Map<String, dynamic> product = {
          'category': productData['category'],
          'description': productData['description'],
          'imageUrls': productData['imageUrls'].join(','),  // Convertir lista de URLs a String
          'name': productData['name'],
          'price': productData['price'],
          'sellerName': productData['sellerName'],
          'timestamp': productData['timestamp'],
          'userId': productData['userId'],
        };

        // Verificar si el producto ya existe en la base de datos local
        var existingProduct = await getProductById(doc.id);

        if (existingProduct == null) {
          await insertProduct(product);  // Insertar producto si no existe
        } else {
          await updateProduct(product);  // Actualizar producto si ya existe
        }
      }
    } catch (e) {
      print('Error sincronizando productos con Firebase: $e');
    }
  }


}
