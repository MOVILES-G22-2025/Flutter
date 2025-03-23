// lib/domain/repositories/product_repository.dart

import 'package:image_picker/image_picker.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> searchProducts(String query);

  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  });

  Stream<List<Product>> getProductsStream();


}

