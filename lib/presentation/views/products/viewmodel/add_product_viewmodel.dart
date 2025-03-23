import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';

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
    required double price,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final product = Product(
        id: '',
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrls: [],
        sellerName: '',
        favoritedBy: [],
      );

      await _productRepository.addProduct(images: images, product: product);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
