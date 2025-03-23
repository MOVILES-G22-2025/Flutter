import 'package:flutter/cupertino.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/product_repository.dart';

/// ViewModel that handles product search functionality.
/// Uses Algolia (via ProductRepository) to retrieve search results.
class ProductSearchViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  List<Product> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  ProductSearchViewModel(this._repository);

  // Public getters
  List<Product> get searchResults => _results;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Updates the search query and triggers a new search.
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners(); // Let UI react instantly
    search(query);     // Run the actual search
  }

  /// Executes a search using the repository (Algolia).
  Future<void> search(String query) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // UI can show loading indicator

    try {
      _results = await _repository.searchProducts(query);
      print("Resultados de Algolia para '$query': $_results");
    } catch (e) {
      _errorMessage = e.toString();
      _results = [];
    }

    _isLoading = false;
    notifyListeners(); // Show results or error
  }
}
