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
    final path = join(await getDatabasesPath(), 'app.db'); // Nombre de la base de datos actualizado
    return await openDatabase(path,
      version: 2,
      onCreate: (db, version) async {
        // Crear tabla de productos
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

        // Crear tabla de usuarios
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT,
            career TEXT,
            semester TEXT,
            email TEXT
          );
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // Si la base de datos es de una versión anterior, crear las tablas
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

          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT,
              career TEXT,
              semester TEXT,
              email TEXT
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
