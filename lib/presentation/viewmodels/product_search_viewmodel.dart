// lib/presentation/viewmodels/product_search_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

class ProductSearchViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  // Estado de la UI
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  // Constructor con inyección de dependencia
  ProductSearchViewModel(this._repository);

  // Getters para exponer a la vista
  List<Map<String, dynamic>> get searchResults => _results;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Actualiza el query y lanza la búsqueda.
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    search(query);
  }

  /// Ejecuta la búsqueda a través del repositorio.
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
