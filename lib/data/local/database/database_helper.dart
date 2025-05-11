// lib/data/local/database/database_helper.dart

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'products.db';
  static const _dbVersion = 5;
  static Database? _database;

  /// Returns a singleton database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens the database, creating or upgrading as needed.
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the two tables: cached_products and pending_products.
  Future<void> _onCreate(Database db, int version) async {
    // Mirror of Firestore products
    await db.execute('''
      CREATE TABLE cached_products (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        category TEXT,
        price REAL,
        sellerName TEXT,
        imageUrls TEXT,
        favoritedBy TEXT DEFAULT '[]',
        timestamp INTEGER,
        userId TEXT
      );
    ''');

    // Queue for offline-created products
    await db.execute('''
      CREATE TABLE pending_products (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        category TEXT,
        price REAL,
        sellerName TEXT DEFAULT '',
        imageUrls TEXT,
        timestamp INTEGER,
        userId TEXT,
        isSynced INTEGER DEFAULT 0
      );
    ''');
  }

  /// Applies schema migrations between versions.
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 4) {
      // v4: add sellerName to pending_products
      await db.execute('''
        ALTER TABLE pending_products
        ADD COLUMN sellerName TEXT DEFAULT '';
      ''');
    }
    if (oldV < 5) {
      // v5: add favoritedBy to cached_products
      await db.execute('''
        ALTER TABLE cached_products
        ADD COLUMN favoritedBy TEXT DEFAULT '[]';
      ''');
    }
  }

  /// Closes the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // —— OPERATIONS ON pending_products ——

  /// Inserts or replaces a product in the offline queue.
  Future<void> savePendingProduct(Map<String, dynamic> product) async {
    final db = await database;

    // Ensure timestamp is an integer.
    if (product['timestamp'] is DateTime) {
      product['timestamp'] =
          (product['timestamp'] as DateTime).millisecondsSinceEpoch;
    }

    // Flatten imageUrls list into comma-separated string.
    if (product['imageUrls'] is List) {
      product['imageUrls'] =
          (product['imageUrls'] as List).cast<String>().join(',');
    }

    await db.insert(
      'pending_products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all not-yet-synced products.
  Future<List<Map<String, dynamic>>> getPendingProducts() async {
    final db = await database;
    return await db.query(
      'pending_products',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  /// Marks a pending product as synced (or you can delete instead).
  Future<void> markPendingAsSynced(String id) async {
    final db = await database;
    await db.update(
      'pending_products',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a pending product after successful sync.
  Future<void> deletePendingProduct(String id) async {
    final db = await database;
    await db.delete(
      'pending_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // —— OPERATIONS ON cached_products ——

  /// Inserts or updates a Firestore-backed product locally.
  Future<void> upsertCachedProduct(Map<String, dynamic> product) async {
    final db = await database;
    if (product['timestamp'] is DateTime) {
      product['timestamp'] =
          (product['timestamp'] as DateTime).millisecondsSinceEpoch;
    }
    if (product['imageUrls'] is List) {
      product['imageUrls'] =
          (product['imageUrls'] as List).cast<String>().join(',');
    }
    if (product['favoritedBy'] is List) {
      product['favoritedBy'] =
          jsonEncode((product['favoritedBy'] as List).cast<String>());
    }
    await db.insert(
      'cached_products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches all cached products, ordered by newest first.

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final db = await database;
    return await db.query('cached_products', orderBy: 'timestamp DESC');
  }

  Future<void> deleteCachedProduct(String id) async {
    final db = await database;
    await db.delete('cached_products', where: 'id = ?', whereArgs: [id]);
  }



  Future<List<Map<String, dynamic>>> getCachedFavorites(String userId) async {
    final db = await database;
    // Buscamos en favoritedBy JSON
    return await db.query(
      'cached_products',
      where: 'favoritedBy LIKE ?',
      whereArgs: ['%"$userId"%'],
      orderBy: 'timestamp DESC',
    );
  }
}
