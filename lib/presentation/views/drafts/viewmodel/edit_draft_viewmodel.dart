import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

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
}