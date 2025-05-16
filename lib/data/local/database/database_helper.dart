import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'products.db';
  static const _dbVersion = 10;
  static Database? _database;

  /// Retorna la instancia singleton de la base de datos.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Abre (o crea/actualiza) la base de datos.
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas iniciales.
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de productos cacheados
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
        userId TEXT,
        isSynced INTEGER DEFAULT 1,
        operation_type TEXT DEFAULT 'create',
        images_to_delete TEXT DEFAULT ''
      );
    ''');

    // Tabla de usuarios sincronizados
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        career TEXT,
        semester TEXT,
        email TEXT,
        profileImageUrl TEXT
      );
    ''');

    // Cola de productos pendientes
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
        isSynced INTEGER DEFAULT 0,
        operation_type TEXT DEFAULT 'create',
        images_to_delete TEXT DEFAULT ''
      );
    ''');

    // Cola de usuarios pendientes
    await db.execute('''
      CREATE TABLE pending_users (
        id TEXT PRIMARY KEY,
        name TEXT,
        career TEXT,
        semester TEXT,
        email TEXT,
        isSynced INTEGER DEFAULT 0,
        profileImageUrl TEXT
      );
    ''');
  }

  /// Aplica migraciones de esquema.
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 4) {
      await db.execute('''
        ALTER TABLE pending_products
        ADD COLUMN sellerName TEXT DEFAULT '';
      ''');
    }
    if (oldV < 5) {
      await db.execute('''
        ALTER TABLE cached_products
        ADD COLUMN favoritedBy TEXT DEFAULT '[]';
      ''');
    }
    if (oldV < 6) {
      await db.execute('''
        ALTER TABLE pending_products
        ADD COLUMN operation_type TEXT DEFAULT 'create';
      ''');
    }
    if (oldV < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT,
          career TEXT,
          semester TEXT,
          email TEXT,
          profileImageUrl TEXT
        );
      ''');
    }
    if (oldV < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_users (
          id TEXT PRIMARY KEY,
          name TEXT,
          career TEXT,
          semester TEXT,
          email TEXT,
          isSynced INTEGER DEFAULT 0,
          profileImageUrl TEXT
        );
      ''');
    }
    if (oldV < 9) {
      await db.execute('''
        ALTER TABLE pending_products
        ADD COLUMN images_to_delete TEXT DEFAULT '';
      ''');
    }
    if (oldV < 10) {
      await db.execute('''
        ALTER TABLE cached_products
        ADD COLUMN isSynced INTEGER DEFAULT 1;
      ''');
      await db.execute('''
        ALTER TABLE cached_products
        ADD COLUMN operation_type TEXT DEFAULT 'create';
      ''');
      await db.execute('''
        ALTER TABLE cached_products
        ADD COLUMN images_to_delete TEXT DEFAULT '';
      ''');
    }
  }

  /// Cierra la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // —— OPERATIONS ON pending_products —— //

  Future<void> savePendingProduct(Map<String, dynamic> product) async {
    final db = await database;
    if (product['timestamp'] is DateTime) {
      product['timestamp'] =
          (product['timestamp'] as DateTime).millisecondsSinceEpoch;
    }
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

  Future<List<Map<String, dynamic>>> getPendingProducts() async {
    final db = await database;
    return await db.query(
      'pending_products',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markPendingAsSynced(String id) async {
    final db = await database;
    await db.update(
      'pending_products',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingProduct(String id) async {
    final db = await database;
    await db.delete(
      'pending_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // —— OPERATIONS ON cached_products —— //

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

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    final db = await database;
    return await db.query('cached_products', orderBy: 'timestamp DESC');
  }

  Future<void> deleteCachedProduct(String id) async {
    final db = await database;
    await db.delete('cached_products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCachedProducts() async {
    final db = await database;
    await db.delete('cached_products');
  }

  Future<List<Map<String, dynamic>>> getCachedFavorites(
      String userId) async {
    final db = await database;
    return await db.query(
      'cached_products',
      where: 'favoritedBy LIKE ?',
      whereArgs: ['%"$userId"%'],
      orderBy: 'timestamp DESC',
    );
  }

  // —— OPERATIONS ON pending_users —— //

  Future<void> savePendingUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'pending_users',
      {
        'id'      : user['id'],
        'name'    : user['name'],
        'career'  : user['career'],
        'semester': user['semester'],
        'email'   : user['email'],
        'isSynced': 0,
        'profileImageUrl': user['profileImageUrl']
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final db = await database;
    return await db.query('pending_users', where: 'isSynced = ?', whereArgs: [0]);
  }

  Future<void> markPendingUserAsSynced(String id) async {
    final db = await database;
    await db.update(
      'pending_users',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingUser(String id) async {
    final db = await database;
    await db.delete('pending_users', where: 'id = ?', whereArgs: [id]);
  }
}
