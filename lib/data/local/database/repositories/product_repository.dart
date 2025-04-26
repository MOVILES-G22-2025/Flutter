import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Insertar un producto
  Future<void> insertProducto(Map<String, dynamic> producto) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'productos',  // Nombre de la tabla
      producto,     // Mapa con los datos del producto
      conflictAlgorithm: ConflictAlgorithm.replace,  // Si hay conflicto, reemplaza el dato
    );
  }

  // Obtener todos los productos
  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await _databaseHelper.database;
    return await db.query('productos');  // Realiza un SELECT de todos los productos
  }

  // Obtener un producto por su ID
  Future<Map<String, dynamic>?> getProductoById(String id) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;  // Retorna el producto encontrado
  }

  // Actualizar un producto
  Future<void> updateProducto(Map<String, dynamic> producto) async {
    final db = await _databaseHelper.database;
    await db.update(
      'productos',
      producto,  // Mapa con los datos a actualizar
      where: 'id = ?',  // Condición para encontrar el producto
      whereArgs: [producto['id']],
    );
  }

  // Eliminar un producto
  Future<void> deleteProducto(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'productos',
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
        'productos',
        {'name': 'Producto 2', 'price': 30.00},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Actualizar otro producto
      await txn.update(
        'productos',
        {'name': 'Producto actualizado', 'price': 35.00},
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  // Sincronizar productos con Firebase
  // Dentro de la clase ProductRepository
  Future<void> sincronizarProductosConFirebase() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('productos').get();

      for (var doc in snapshot.docs) {
        var productoData = doc.data();
        Map<String, dynamic> producto = {
          'category': productoData['category'],
          'description': productoData['description'],
          'imageUrls': productoData['imageUrls'].join(','),  // Convertir lista de URLs a String
          'name': productoData['name'],
          'price': productoData['price'],
          'sellerName': productoData['sellerName'],
          'timestamp': productoData['timestamp'],
          'userId': productoData['userId'],
        };

        // Verificar si el producto ya existe en la base de datos local
        var existingProduct = await getProductoById(doc.id);

        if (existingProduct == null) {
          await insertProducto(producto);  // Insertar producto si no existe
        } else {
          await updateProducto(producto);  // Actualizar producto si ya existe
        }
      }
    } catch (e) {
      print('Error al sincronizar productos con Firebase: $e');
    }
  }


}
