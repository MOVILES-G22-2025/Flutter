/// Contract for managing product favorites in the domain layer.
/// Implementations should handle how favorites are stored (e.g., Firestore, local DB).
abstract class FavoritesRepository {
  /// Adds the product to the user's list of favorites.
  Future<void> addProductToFavorites(String userId, String productId);

  /// Removes the product from the user's list of favorites.
  Future<void> removeProductFromFavorites(String userId, String productId);
}
