abstract class FavoritesRepository {
  Future<void> addProductToFavorites(String userId, String productId);
  Future<void> removeProductFromFavorites(String userId, String productId);
}
