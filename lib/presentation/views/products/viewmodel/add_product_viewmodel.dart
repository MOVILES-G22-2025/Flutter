// lib/presentation/views/products/viewmodel/add_product_viewmodel.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/local/models/draft_product.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';

class AddProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;
  final Stream<bool> connectivityStream;
  late final StreamSubscription<bool> _connectivitySub;

  bool isLoading = false;
  String? errorMessage;
  bool isOnline = true;

  AddProductViewModel(
      this._productRepository, {
        required this.connectivityStream,
      }) {
    // Una única suscripción al stream de conectividad
    _connectivitySub = connectivityStream.listen((online) {
      isOnline = online;
      notifyListeners();
    });
  }

  /// Llamar cuando el widget se destruya para evitar fugas de memoria
  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

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

    final product = Product(
      id: '',
      name: name,
      description: description,
      category: category,
      price: price,
      imageUrls: [],
      sellerName: '',
      favoritedBy: [],
      timestamp: DateTime.now(),
      userId: '',
    );

    try {
      await _productRepository.addProduct(images: images, product: product);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProductOffline({
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
      final id = const Uuid().v4();
      final imagePaths = images
          .where((e) => e != null)
          .map((e) => e!.path)
          .toList();
      final productMap = {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'sellerName': '',
        'imageUrls': imagePaths.join(','),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': '',
        'isSynced': 0,
      };
      await _productRepository.saveOfflineProduct(productMap);
    } catch (e) {
      errorMessage = 'Error saving product locally: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveDraft({
    required String name,
    required String description,
    required String category,
    required double? price,
    required List<XFile?> images,
  }) async {
    try {
      // Solo guardar si hay algún campo lleno
      if (name.isEmpty && 
          description.isEmpty && 
          (price == null || price == 0) && 
          category.isEmpty && 
          images.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final imagePaths = images
          .where((e) => e != null)
          .map((e) => e!.path)
          .toList();
      
      final draft = DraftProduct(
        id: const Uuid().v4(),
        name: name,
        description: description,
        price: price ?? 0.0,
        category: category,
        userId: _productRepository.currentUserId,
        imagePaths: imagePaths,
        createdAt: now,
        lastUpdated: now,
      );
      
      draft.updateCompleteness();
      await _productRepository.saveDraftProduct(draft);
    } catch (e) {
      errorMessage = 'Error guardando borrador: $e';
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
      errorMessage = 'Error actualizando borrador: $e';
      notifyListeners();
    }
  }
}
