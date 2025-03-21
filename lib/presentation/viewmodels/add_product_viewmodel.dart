// lib/presentation/viewmodels/add_product_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

class AddProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  bool isLoading = false;
  String? errorMessage;

  AddProductViewModel(this._productRepository);

  Future<void> addProduct({
    required List<XFile?> images,
    required String name,
    required String description,
    required String category,
    required String price,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _productRepository.addProduct(
        images: images,
        name: name,
        description: description,
        category: category,
        price: price,
      );
    } catch (e) {
      errorMessage = "Error al publicar el producto: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
