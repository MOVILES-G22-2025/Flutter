import 'package:flutter/cupertino.dart';

import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';

class ProductSearchViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  List<Product> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  ProductSearchViewModel(this._repository);

  List<Product> get searchResults => _results;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    search(query);
  }

  Future<void> search(String query) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _results = await _repository.searchProducts(query);
      print("Resultados de Algolia para '$query': $_results");
    } catch (e) {
      _errorMessage = e.toString();
      _results = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
