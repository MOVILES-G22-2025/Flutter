import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../local/models/user_session.dart';
import '../credential_hive_service.dart'; // si usas Hive aquí también

/// Servicio que guarda y lee la sesión activa usando
/// flutter_secure_storage (cifrado nativo).
class LocalStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Guarda los datos de sesión del usuario.
  Future<void> saveActiveSession(UserSessionModel user) async {
    await _storage.write(key: 'isLoggedIn', value: 'true');
    await _storage.write(key: 'uid',         value: user.uid);
    await _storage.write(key: 'email',       value: user.email);
    await _storage.write(key: 'name',        value: user.name);
  }

  /// Lee la sesión activa; retorna null si no hay sesión.
  Future<UserSessionModel?> readSession() async {
    final isLoggedIn = await _storage.read(key: 'isLoggedIn');
    if (isLoggedIn != 'true') return null;

    final uid   = await _storage.read(key: 'uid');
    final email = await _storage.read(key: 'email');
    final name  = await _storage.read(key: 'name');

    if (uid == null || email == null || name == null) return null;
    return UserSessionModel(
      uid: uid,
      email: email,
      name: name,
      isLoggedIn: true,
    );
  }

  /// Borra la sesión activa.
  Future<void> clearSession() async {
    await _storage.delete(key: 'isLoggedIn');
    await _storage.delete(key: 'uid');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'name');
  }
}
