// lib/presentation/views/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/common/navigation_bar.dart';
import 'package:senemarket/common/search_bar.dart' as searchBar;
import 'package:senemarket/common/filter_bar.dart';
import 'package:senemarket/presentation/viewmodels/product_search_viewmodel.dart';
import 'package:senemarket/presentation/views/product_view/product_card.dart';
import 'package:senemarket/constants.dart' as constants;

// Temporalmente, si aún no migras la lógica de getProductsStream
// a un repositorio, puedes usar tu facade. Pero lo ideal es
// usar ProductRepositoryImpl con un StreamBuilder.
import 'package:senemarket/data/repositories/product_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Categorías seleccionadas para filtrar
  List<String> _selectedCategories = [];

  // Conteo de clics por categoría
  Map<String, int> _categoryClicks = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final _productRepo = ProductRepositoryImpl(); // Idealmente via Provider

  @override
  void initState() {
    super.initState();
    _loadUserClicks();
  }

  Future<void> _loadUserClicks() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data();
      setState(() {
        _categoryClicks = Map<String, int>.from(data?['categoryClicks'] ?? {});
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Incrementa el contador de clics de una categoría y lo persiste.
  void _incrementCategoryClick(String category) async {
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  /// Ordena las categorías según los clics
  List<String> get _categoriesSortedByClicks {
    final allCategories = constants.ProductClassification.categories;
    final sortedList = allCategories.toList()
      ..sort((a, b) {
        final clicksA = _categoryClicks[a] ?? 0;
        final clicksB = _categoryClicks[b] ?? 0;
        return clicksB.compareTo(clicksA);
      });
    return sortedList;
  }

  /// Filtra los productos usando el query del ViewModel y las categorías
  List<Map<String, dynamic>> _filterProducts(
      List<Map<String, dynamic>> baseProducts,
      ProductSearchViewModel searchViewModel,
      ) {
    final searchQuery = searchViewModel.searchQuery;

    // Por ahora, el searchViewModel.searchResults está vacío a menos
    // que implementes Algolia en el viewModel.
    // Si no hay query, tomamos baseProducts
    final List<Map<String, dynamic>> products = searchQuery.isNotEmpty
        ? searchViewModel.searchResults
        : baseProducts;

    // Filtrar por categorías
    if (_selectedCategories.isEmpty) {
      return products;
    }

    return products.where((product) {
      final productCategory = product['category']?.toString().toLowerCase() ?? '';
      return _selectedCategories.any((selected) =>
          productCategory.contains(selected.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productSearchViewModel = context.watch<ProductSearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SearchBar
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: searchBar.SearchBar(
                hintText: 'Search products...',
                onChanged: (value) {
                  productSearchViewModel.updateSearchQuery(value);
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // FilterBar
            FilterBar(
              categories: _categoriesSortedByClicks,
              selectedCategories: _selectedCategories,
              onCategoriesSelected: (selected) {
                setState(() {
                  _selectedCategories = selected;
                });
              },
            ),
            const SizedBox(height: 16.0),
            // Stream de productos
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _productRepo.getProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No products added yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final allProducts = snapshot.data!;
                  final filteredProducts = _filterProducts(
                    allProducts,
                    productSearchViewModel,
                  );

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onCategoryTap: (category) {
                          _incrementCategoryClick(category);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
