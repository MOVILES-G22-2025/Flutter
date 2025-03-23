import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';

/// ViewModel used for handling product creation.
/// It connects the form UI with the ProductRepository.
class AddProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  bool isLoading = false;
  String? errorMessage;

  AddProductViewModel(this._productRepository);

  /// Adds a new product with images and details provided from the form.
  Future<void> addProduct({
    required List<XFile?> images,
    required String name,
    required String description,
    required String category,
    required double price,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); // Notifies UI to show loading indicator

    try {
      // Create a new product entity with empty id/image/seller (filled later)
      final product = Product(
        id: '', // Will be generated in the backend
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrls: [], // Uploaded later
        sellerName: '', // Retrieved from backend
        favoritedBy: [],
      );

      // Send product data to repository for uploading
      await _productRepository.addProduct(images: images, product: product);
    } catch (e) {
      errorMessage = e.toString(); // Store error to display in UI
    }

    isLoading = false;
    notifyListeners(); // Updates UI once done
  }
}
