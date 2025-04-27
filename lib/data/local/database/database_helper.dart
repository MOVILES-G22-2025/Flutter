import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  /// Getter que devuelve la instancia única de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa (o crea) la base de datos y las tablas necesarias
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(path,
      version: 2,
      onCreate: (db, version) async {
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
            userId TEXT
          );
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // Crea la tabla si antes existía sólo la v1
          await db.execute('''
            CREATE TABLE IF NOT EXISTS products (
              id TEXT PRIMARY KEY,
              category TEXT,
              description TEXT,
              imageUrls TEXT,
              name TEXT,
              price REAL,
              sellerName TEXT,
              timestamp INTEGER,
              userId TEXT
            );
          ''');
        }
      },
    );
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
