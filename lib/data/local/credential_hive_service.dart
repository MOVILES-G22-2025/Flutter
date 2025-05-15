import 'package:hive/hive.dart';

class CredentialHiveService {
  final Box<String> _box;

  CredentialHiveService() : _box = Hive.box<String>('user_credentials');

  /// Guarda la contraseña hasheada bajo la clave email
  Future<void> saveCredentials(String email, String hashedPassword) async {
    await _box.put(email, hashedPassword);
  }

  /// Devuelve el hash almacenado para este email (o null si no existe)
  String? getStoredHash(String email) {
    return _box.get(email);
  }

  /// Elimina las credenciales de este email
  Future<void> clearCredentials(String email) async {
    await _box.delete(email);
  }
}