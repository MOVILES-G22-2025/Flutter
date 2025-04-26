import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Método para obtener la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  // Inicializa la base de datos y crea la tabla
  Future<Database> _initDatabase() async {
    // Obtiene la ruta donde se almacenará la base de datos
    String path = join(await getDatabasesPath(), 'productos.db');

    // Abre la base de datos (la crea si no existe)
    return await openDatabase(path, onCreate: (db, version) async {
      // Sentencia SQL para crear la tabla
      await db.execute('''
        CREATE TABLE productos (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          nombre TEXT, 
          precio REAL
        );
      ''');
    }, version: 1);
  }

  // Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
