import 'package:image_picker/image_picker.dart';

import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> searchProducts(String query);

  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  });

  Stream<List<Product>> getProductsStream();

  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  });

  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  });
}
