import 'package:flutter/material.dart';
import '../services/product_search_repository.dart';

class ProductSearchModel extends ChangeNotifier {
  final ProductSearchRepository _repository;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  ProductSearchModel({ProductSearchRepository? repository})
      : _repository = repository ?? ProductSearchRepository();

  // Nuevo getter para acceder a los resultados desde HomePage como searchResults
  List<Map<String, dynamic>> get searchResults => _results;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    search(query); // Opcional: puedes llamar a la búsqueda inmediatamente o implementar un debounce.
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
