import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ---------- helpers ----------

  /// Convierte un documento de Firestore en un mapa listo para SQLite
  Map<String, dynamic> _firestoreToSqlite(Map<String, dynamic> data, String id) {
    return {
      'id'       : id,                        // PK
      'name'     : data['name'],
      'career'   : data['career'],
      'semester' : data['semester'],
      'email'    : data['email'],
    };
  }

  // ---------- CRUD SQLite ----------

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await _databaseHelper.database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await _databaseHelper.database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await _databaseHelper.database;
    await db.update('users', user,
        where: 'id = ?', whereArgs: [user['id']]);
  }

  Future<void> deleteUser(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Sync Firebase → SQLite ----------

  Future<void> sincronizarUsersConFirebase() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').get();

      for (final doc in snapshot.docs) {
        final map = _firestoreToSqlite(doc.data(), doc.id);
        (await getUserById(doc.id)) == null
            ? await insertUser(map)
            : await updateUser(map);
      }
    } catch (e) {
      print('Error sincronizando usuarios con Firebase: $e');
    }
  }
}