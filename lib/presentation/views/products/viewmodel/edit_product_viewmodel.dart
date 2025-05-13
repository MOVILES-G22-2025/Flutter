import 'dart:isolate';

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

    bool result = false;

    await _productRepository.updateProduct(
      productId: productId, 
      updatedProduct: updatedProduct,
      newImages: newImages,
      imagesToDelete: imagesToDelete,
    ).then((_) {
      result = true;
    }).catchError((e) {
      errorMessage = e.toString();
      result = false;
    });

    isLoading = false;
    notifyListeners();
    return result;
  }

  //Isolate strategy
  Future<void> clearEditedImagesFromCache(List<String> oldUrls, List<String> updatedUrls) async {
    final receivePort = ReceivePort();

    await Isolate.spawn<_ImageCleanupPayload>(
      _clearImagesWorker,
      _ImageCleanupPayload(
        oldUrls: oldUrls,
        updatedUrls: updatedUrls,
        sendPort: receivePort.sendPort,
      ),
    );

    await receivePort.first; //Esperar confirmación
    receivePort.close();
  }
}

//Payload para pasar a la función aislada
class _ImageCleanupPayload {
  final List<String> oldUrls;
  final List<String> updatedUrls;
  final SendPort sendPort;

  _ImageCleanupPayload({
    required this.oldUrls,
    required this.updatedUrls,
    required this.sendPort,
  });
}

//Función ejecutada en el Isolate
void _clearImagesWorker(_ImageCleanupPayload payload) async {
  final manager = CustomCacheManager.instance;

  for (final url in payload.oldUrls) {
    if (!payload.updatedUrls.contains(url)) {
      await manager.removeFile(url);
    }
  }
  //Notifica que terminó
  payload.sendPort.send(true);
}
