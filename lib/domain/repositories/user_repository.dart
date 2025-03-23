// lib/domain/repositories/user_repository.dart

abstract class UserRepository {
  Future<Map<String, dynamic>?> getUserData();
  Future<void> updateUserData(Map<String, dynamic> data);
}
