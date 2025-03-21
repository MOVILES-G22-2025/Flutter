import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/navigation_bar.dart';
import 'package:senemarket/common/search_bar.dart' as searchBar;
import '../common/filter_bar.dart';
import '../models/product_search_model.dart';
import '../views/product_view/product_card.dart';
import '../constants.dart' as constants;
import 'package:senemarket/services/product_facade.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // Eliminamos _addedProducts porque ahora usaremos un StreamBuilder

  // Lista de categorías seleccionadas para filtrar.
  List<String> _selectedCategories = [];

  // Mapa para llevar la cuenta de los clics por categoría.
  Map<String, int> _categoryClicks = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Instancia del facade
  final ProductFacade _productFacade = ProductFacade();

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
    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  /// Retorna las categorías ordenadas según la cantidad de clics.
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

  /// Filtra los productos usando tanto el query de búsqueda
  /// como las categorías seleccionadas.
  List<Map<String, dynamic>> _filterProducts(
      List<Map<String, dynamic>> baseProducts) {
    final productSearchModel = Provider.of<ProductSearchModel>(context);

    final searchQuery = productSearchModel.searchQuery;

    // Si hay búsqueda, usamos los resultados de Algolia (aunque sean vacíos)
    final List<Map<String, dynamic>> products = searchQuery.isNotEmpty
        ? productSearchModel.searchResults
        : baseProducts;

    // Aplicamos el filtro de categorías
    if (_selectedCategories.isEmpty) {
      return products;
    }

    return products.where((product) {
      final productCategory =
          product['category']?.toString().toLowerCase() ?? '';
      return _selectedCategories.any((selected) =>
          productCategory.contains(selected.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SearchBar en la parte superior
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: searchBar.SearchBar(
                hintText: 'Search products...',
                onChanged: (value) {
                  // Actualiza el query en ProductSearchModel
                  Provider.of<ProductSearchModel>(context, listen: false)
                      .updateSearchQuery(value);
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // FilterBar debajo del SearchBar
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
            // Lista de productos filtrados usando un StreamBuilder
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _productFacade.getProductsStream(),
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
                  // Obtenemos los productos del stream y aplicamos filtros
                  final filteredProducts =
                  _filterProducts(snapshot.data!);

                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
