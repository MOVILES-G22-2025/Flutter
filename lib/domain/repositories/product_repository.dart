// lib/domain/repositories/product_repository.dart
import 'package:image_picker/image_picker.dart';

abstract class ProductRepository {
  Future<void> addProduct({
    required List<XFile?> images,
    required String name,
    required String description,
    required String category,
    required String price,
  });

  Stream<List<Map<String, dynamic>>> getProductsStream();

  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  });

  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  });

  Future<List<Map<String, dynamic>>> searchProducts(String query);

}
