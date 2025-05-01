import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(
      path,
      version: 3,                           // ← Subimos a la 3
      onCreate: (db, version) async {
        // Instalaciones nuevas: tabla ya con isSynced
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            category TEXT,
            description TEXT,
            imageUrls TEXT,
            name TEXT,
            price REAL,
            sellerName TEXT,
            timestamp INTEGER,
            userId TEXT,
            isSynced INTEGER DEFAULT 0
          );
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        // Migraciones: de <3 añadimos la columna
        if (oldV < 3) {
          await db.execute('''
            ALTER TABLE products ADD COLUMN isSynced INTEGER DEFAULT 0;
          ''');
        }
      },
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> saveOfflineProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final db = await database;
    return await db.query(
      'products',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(String productId) async {
    final db = await database;
    await db.update(
      'products',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deleteOfflineProduct(String productId) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
