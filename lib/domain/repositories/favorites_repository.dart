import '../../core/services/connectivity_service.dart';

/// Contract for managing product favorites in the domain layer.
/// Implementations should handle how favorites are stored (e.g., Firestore, local DB).
abstract class FavoritesRepository {
  ConnectivityService get connectivity;

  /// Adds the product to the user's list of favorites.
  Future<void> addProductToFavorites(String userId, String productId);

  /// Removes the product from the user's list of favorites.
  Future<void> removeProductFromFavorites(String userId, String productId);

  fetchFavorites({required String userId, required bool forceRemote}) {}
}
