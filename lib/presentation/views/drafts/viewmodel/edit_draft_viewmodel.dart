import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

import '../../../../data/local/models/draft_product.dart';

class EditDraftViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  bool isLoading = false;

  EditDraftViewModel(this._productRepository);

  Future<bool> publishDraft({
    required Product product,
    required List<XFile?> newImages,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      await _productRepository.addProduct(
        images: newImages,
        product: product,
      );

      return true;
    } catch (e) {
      print("❌ Error publicando borrador: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDraft({
    required String draftId,
    required String name,
    required String description,
    required String category,
    required double? price,
    required List<XFile?> images,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final imagePaths = images
          .where((e) => e != null)
          .map((e) => e!.path)
          .toList();
      
      final draft = DraftProduct(
        id: draftId,
        name: name,
        description: description,
        price: price ?? 0.0,
        category: category,
        userId: _productRepository.currentUserId,
        imagePaths: imagePaths,
        lastUpdated: now,
      );
      
      draft.updateCompleteness();
      await _productRepository.saveDraftProduct(draft);
    } catch (e) {
      print("❌ Error actualizando borrador: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}