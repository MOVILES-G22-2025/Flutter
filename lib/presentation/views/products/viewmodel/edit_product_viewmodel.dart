import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

import '../../../../core/services/custom_cache_manager.dart';

class EditProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  bool isLoading = false;
  String? errorMessage;

  EditProductViewModel(this._productRepository);

  /// Updates a product, including handling new images and deleting removed ones.
  Future<bool> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.updateProduct(
        productId: productId,
        updatedProduct: updatedProduct,
        newImages: newImages,
        imagesToDelete: imagesToDelete,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //Isolate strategy
  Future<void> clearEditedImagesFromCache(List<String> oldUrls, List<String> updatedUrls) async {
    await compute(_clearImagesWorker, {
      'oldUrls': oldUrls,
      'updatedUrls': updatedUrls,
    });
  }

  void _clearImagesWorker(Map<String, dynamic> args) async {
    final oldUrls = List<String>.from(args['oldUrls']);
    final updatedUrls = List<String>.from(args['updatedUrls']);
    final manager = CustomCacheManager.instance;

    for (final url in oldUrls) {
      if (!updatedUrls.contains(url)) {
        await manager.removeFile(url);
      }
    }
  }
}
