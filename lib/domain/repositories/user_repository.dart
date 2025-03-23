/// Defines the contract for managing user profile data in the domain layer.
/// It does not depend on how or where the data is stored.
abstract class UserRepository {
  /// Gets the current user's data as a key-value map.
  /// Returns null if no user is found or logged in.
  Future<Map<String, dynamic>?> getUserData();

  /// Updates the current user's data with the given map.
  Future<void> updateUserData(Map<String, dynamic> data);
}
