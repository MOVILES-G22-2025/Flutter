import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/core/services/connectivity_service.dart';
import 'package:senemarket/core/services/custom_cache_manager.dart';

class EditProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  bool isLoading = false;
  String? errorMessage;

  EditProductViewModel(this._productRepository);

  // Exponer el servicio de conectividad
  ConnectivityService get connectivity => _productRepository.connectivity;

  /// 1) IMPLEMENTACIÓN CON async/await + try/catch/finally

  // Future
  Future<bool> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
    // async
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // await
    final isOnline = await connectivity.isOnline$.first;

    // 3) Preparo el Future que va a realizar la operación
    Future<bool> operation;
    if (!isOnline) {
      // — Si estamos offline guardamos en pending
      operation = _productRepository
          .updateProductOffline(
        productId: productId,
        updatedProduct: updatedProduct,
        newImages: newImages,
        imagesToDelete: imagesToDelete,
      ) // then
          .then((_) => true)
        // catchError
          .catchError((e) {                   // en fallo capturamos mensaje
        errorMessage = e.toString();
        return false;
      });
    } else {
      // — Si hay conexión actualizamos en remoto
      operation = _productRepository
          .updateProduct(
        productId: productId,
        updatedProduct: updatedProduct,
        newImages: newImages,
        imagesToDelete: imagesToDelete,
      )
          .then((_) => true)
          .catchError((e) {
        errorMessage = e.toString();
        return false;
      });
    }

    // whenComplete
    operation.whenComplete(() {
      isLoading = false;
      notifyListeners();
    });

    // Devuelvo el resultado del Future handler
    return operation;
  }

  // Isolate strategy
  Future<void> clearEditedImagesFromCache(
      List<String> oldUrls, List<String> updatedUrls) async {
    final receivePort = ReceivePort();

    await Isolate.spawn<_ImageCleanupPayload>(
      _clearImagesWorker,
      _ImageCleanupPayload(
        oldUrls: oldUrls,
        updatedUrls: updatedUrls,
        sendPort: receivePort.sendPort,
      ),
    );

    await receivePort.first; // Esperar confirmación
    receivePort.close();
  }
}

// Payload para pasar a la función aislada
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

// Función ejecutada en el Isolate
void _clearImagesWorker(_ImageCleanupPayload payload) async {
  final manager = CustomCacheManager.instance;

  for (final url in payload.oldUrls) {
    if (!payload.updatedUrls.contains(url)) {
      await manager.removeFile(url);
    }
  }
  // Notifica que terminó
  payload.sendPort.send(true);
}
