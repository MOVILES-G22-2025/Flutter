abstract class UserRepository {
  Future<Map<String, dynamic>?> getUserData();

  Future<void> updateUserData(Map<String, dynamic> data);

  /// Adds a product ID to the current user's list of favorites.
  Future<void> addFavorite(String productId);

  /// Removes a product ID from the current user's list of favorites.
  Future<void> removeFavorite(String productId);

  /// Retrieves the user's category click map.
  Future<Map<String, int>> getCategoryClicks(String userId);

  /// Increments a specific category click count.
  Future<void> incrementCategoryClick(String userId, String category);

  Future<void> syncPendingUsers();

  Future<String?> getUserProfileImage(String userId);
}

