import 'package:image_picker/image_picker.dart';
import '../entities/product.dart';

/// Defines the contract for product-related actions in the domain layer.
/// Responsible for searching, adding, and streaming product data.
abstract class ProductRepository {
  /// Searches products by a keyword or phrase.
  /// Returns a list of matching products.
  Future<List<Product>> searchProducts(String query);

  /// Adds a new product with images.
  /// The implementation handles how and where the product is saved.
  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  });

  /// Provides a real-time stream of all products.
  /// Useful for home page or product listings.
  Stream<List<Product>> getProductsStream();

  /// Updates an existing product with new data and images.
  Future<void> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  });

  /// Deletes a product from the database.
  Future<void> deleteProduct(String productId);
}
