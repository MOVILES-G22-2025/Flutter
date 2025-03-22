// lib/presentation/viewmodels/add_product_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

import '../../domain/entities/product.dart';

class AddProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  bool isLoading = false;
  String? errorMessage;

  AddProductViewModel(this._productRepository);

// Ejemplo de viewmodel/add_product_viewmodel.dart

  Future<void> addProduct({
    required List<XFile?> images,
    required String name,
    required String description,
    required String category,
    required double price,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Crear la entidad de dominio
      final product = Product(
        id: '', // Se asignará en Firestore
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrls: [],
        sellerName: '',
        favoritedBy: [],
      );

      // 2. Llamar al repo con la entidad
      await _productRepository.addProduct(images: images, product: product);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }


}