import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../common/navigation_bar.dart';
import 'package:senemarket/common/search_bar.dart' as searchBar;
import '../common/filter_bar.dart';
import '../views/product_view/product_card.dart';
import '../constants.dart' as constants;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _addedProducts = [];

  String _searchQuery = '';

  // Lista de categorías seleccionadas para filtrar.
  List<String> _selectedCategories = [];

  // Mapa para llevar la cuenta de los clics por categoría (para ordenarlas).
  Map<String, int> _categoryClicks = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid /* Obtén el ID del usuario, por ejemplo, de FirebaseAuth.currentUser.uid */;

  @override
  void initState() {
    super.initState();
    _loadUserClicks();

  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FirebaseFirestore.instance
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      List<Map<String, dynamic>> products = [];
      for (var doc in querySnapshot.docs) {
        products.add(doc.data());
      }
      setState(() {
        _addedProducts = products;
      });
    });
  }

  Future<void> _loadUserClicks() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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

  /// Se llama cuando se hace clic en un producto.
  /// Incrementa el contador de la categoría de ese producto.
  void _incrementCategoryClick(String category) async {
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': { category: FieldValue.increment(1) }
    }, SetOptions(merge: true));
  }

  /// lista de categorías ordenadas según la cantidad de clics (más altos primero).
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

  List<Map<String, dynamic>> get _filteredProducts {
    // Filtrado por búsqueda
    final filteredBySearch = _searchQuery.isEmpty
        ? _addedProducts
        : _addedProducts.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Si no hay filtros, retorna todos los productos
    if (_selectedCategories.isEmpty) {
      return filteredBySearch;
    }

    // Filtrado por las categorías seleccionadas
    return filteredBySearch.where((product) {
      final productCategory =
          product['category']?.toString().toLowerCase() ?? '';
      return _selectedCategories.any(
              (selected) => productCategory.contains(selected.toLowerCase()));
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
            // SearchBar en la parte superior con padding
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: searchBar.SearchBar(
                hintText: 'Buscar productos...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // FilterBar justo debajo del SearchBar
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
            // Lista de productos
            Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(
                child: Text(
                  "No products added yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
                  : GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onCategoryTap: (category) {
                      _incrementCategoryClick(category);
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
