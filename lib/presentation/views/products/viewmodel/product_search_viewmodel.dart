import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  /// Filters out products created by the current user.
  Future<void> search(String query) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // UI can show loading indicator

    try {
      final allResults = await _repository.searchProducts(query);
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Filter out products created by the current user
      _results = userId == null
          ? allResults
          : allResults.where((product) => product.userId != userId).toList();

      print("Filtered Algolia results for '$query': $_results");
      print(userId);

    } catch (e) {
      print("aaa");
      _errorMessage = e.toString();
      _results = [];
    }

    _isLoading = false;
    notifyListeners(); // Show results or error
  }
}
