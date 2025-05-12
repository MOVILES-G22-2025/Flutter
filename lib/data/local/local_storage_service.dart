import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_keys.dart';
import 'user_session_model.dart';

class LocalStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Guardar sesión activa
  Future<void> saveActiveSession(UserSessionModel user) async {
    await _storage.write(key: SecureKeys.isLoggedIn, value: 'true');
    await _storage.write(key: SecureKeys.uid, value: user.uid);
    await _storage.write(key: SecureKeys.email, value: user.email);
    await _storage.write(key: SecureKeys.name, value: user.name);
  }

  /// Guardar credenciales locales
  Future<void> saveLocalCredentials({
    required String email,
    required String hashedPassword,
  }) async {
    await _storage.write(key: SecureKeys.credentialsEmail, value: email);
    await _storage.write(key: SecureKeys.credentialsHashedPassword, value: hashedPassword);
  }

  /// Leer estado de sesión
  Future<UserSessionModel?> readSession() async {
    final isLoggedIn = await _storage.read(key: SecureKeys.isLoggedIn);
    if (isLoggedIn != 'true') return null;

    final uid = await _storage.read(key: SecureKeys.uid);
    final email = await _storage.read(key: SecureKeys.email);
    final name = await _storage.read(key: SecureKeys.name);

    if (uid == null || email == null || name == null) return null;

    return UserSessionModel(
      uid: uid,
      email: email,
      name: name,
      isLoggedIn: true,
    );
  }

  /// Obtener credenciales guardadas (para login sin red)
  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: SecureKeys.credentialsEmail);
    final password = await _storage.read(key: SecureKeys.credentialsHashedPassword);

    if (email == null || password == null) return null;
    return {
      'email': email,
      'password': password,
    };
  }

  /// Cerrar sesión (borra estado de login)
  Future<void> clearSession() async {
    await _storage.delete(key: SecureKeys.isLoggedIn);
    await _storage.delete(key: SecureKeys.uid);
    await _storage.delete(key: SecureKeys.name);
    await _storage.delete(key: SecureKeys.email);
  }
}
