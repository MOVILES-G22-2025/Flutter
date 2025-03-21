// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  /// Retorna `null` si inicia sesión con éxito,
  /// o un mensaje de error en caso de fallo.
  Future<String?> signInWithEmailAndPassword(String email, String password);

  /// Retorna `null` si el registro es exitoso,
  /// o un mensaje de error en caso de fallo.
  Future<String?> signUpWithEmailAndPassword(
      String email,
      String password,
      String name,
      String career,
      String semester,
      );
}
