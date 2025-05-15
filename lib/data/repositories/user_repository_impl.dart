// lib/data/datasources/remote/user_repository_impl.dart
// lib/data/datasources/remote/user_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:senemarket/data/local/database/database_helper.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity      _conn      = Connectivity();
  final DatabaseHelper    _dbHelper  = DatabaseHelper();

  // ─── ONLINE-FIRST / OFFLINE-FALLBACK ─────────────────────────

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final status = await _conn.checkConnectivity();
    if (status != ConnectivityResult.none) {
      // ONLINE: leer de Firestore y cachear en SQLite
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        final userMap = {
          'id'      : user.uid,
          'name'    : data['name'],
          'career'  : data['career'],
          'semester': data['semester'],
          'email'   : data['email'],
        };
        await (await _dbHelper.database).insert(
          'users',
          userMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return data;
      }
      return null;
    } else {
      // OFFLINE: leer solo de SQLite
      final rows = await (await _dbHelper.database).query(
        'users',
        where: 'id = ?',
        whereArgs: [user.uid],
      );
      return rows.isNotEmpty ? rows.first : null;
    }
  }

  @override
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    data['id'] = user.uid; // asegurar PK

    final status = await _conn.checkConnectivity();
    if (status != ConnectivityResult.none) {
      // ONLINE: actualizar Firestore y luego SQLite
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'name'    : data['name'],
        'career'  : data['career'],
        'semester': data['semester'],
        'email'   : data['email'],
      }, SetOptions(merge: true));

      await (await _dbHelper.database).insert(
        'users',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // OFFLINE: actualizar SQLite y encolar para sincronizar luego
      await (await _dbHelper.database).insert(
        'users',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _dbHelper.savePendingUser(data);
    }
  }

  @override
  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'favorites': FieldValue.arrayUnion([productId]),
    });
  }

  @override
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'favorites': FieldValue.arrayRemove([productId]),
    });
  }

  @override
  Future<Map<String, int>> getCategoryClicks(String userId) async {
    final doc  = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null || data['categoryClicks'] == null) return {};
    return Map<String, int>.from(data['categoryClicks']);
  }

  @override
  Future<void> incrementCategoryClick(String userId, String category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  @override
  Future<void> syncPendingUsers() async {
    final pendientes = await _dbHelper.getPendingUsers();
    for (final u in pendientes) {
      await _firestore
          .collection('users')
          .doc(u['id'])
          .set({
        'name'    : u['name'],
        'career'  : u['career'],
        'semester': u['semester'],
        'email'   : u['email'],
      }, SetOptions(merge: true));
      await _dbHelper.markPendingUserAsSynced(u['id']);
    }
  }

  // ─── CRUD LOCAL SQLITE ────────────────────────────────────────

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    await db.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Sincroniza **todos** los documentos /users de Firestore → SQLite
  Future<void> sincronizarUsersConFirebase() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        final map = _firestoreToSqliteUser(doc.data(), doc.id);
        final exists = await getUserById(doc.id);
        if (exists == null) {
          await insertUser(map);
        } else {
          await updateUser(map);
        }
      }
    } catch (e) {
      print('Error sincronizando usuarios con Firebase: $e');
    }
  }

  /// Helper para convertir Firestore → SQLite
  Map<String, dynamic> _firestoreToSqliteUser(
      Map<String, dynamic> data,
      String id,
      ) {
    return {
      'id'       : id,
      'name'     : data['name'],
      'career'   : data['career'],
      'semester' : data['semester'],
      'email'    : data['email'],
    };
  }
}
