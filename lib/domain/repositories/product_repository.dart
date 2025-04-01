import 'package:image_picker/image_picker.dart';
import '../entities/product.dart';

abstract class ProductRepository {
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
}
