import 'package:image_picker/image_picker.dart';
import 'package:senemarket/data/local/models/draft_product.dart';
import '../entities/product.dart';
import '../../core/services/connectivity_service.dart';

abstract class ProductRepository {
  String get currentUserId;
  ConnectivityService get connectivity;

  Future<List<Product>> searchProducts(String query);

  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  });

  Stream<List<Product>> getProductsStream();

  Future<void> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  });

  Future<void> updateProductOffline({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  });

  Future<void> deleteProduct(String productId);

  /// Increments the favorite count for a product and logs user interaction.
  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  });

  /// Decrements the favorite count and removes user interaction log.
  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  });

  /// Logs a product click from a user.
  Future<void> logProductClick(String userId, String productId);

  saveOfflineProduct(Map<String, Object> productMap) {}

  saveDraftProduct(DraftProduct draft) {}

  Future<int> getProductClickCount(String productId);

  fetchProductClickCount(String productId) {}

  /// Obtiene los productos de la caché local
  Future<List<Product>> getCachedProducts();

  /// Obtiene los productos del usuario, online u offline
  Future<List<Product>> getUserProducts(String userId);

  /// Adds a product to the current user's favorites
  Future<void> addToFavorites(String productId);

  /// Removes a product from the current user's favorites
  Future<void> removeFromFavorites(String productId);

  /// Gets the click count for a specific product
  Future<int> getClickCount(String productId);

  /// Records a click on a product
  Future<void> recordClick(String productId);
}
