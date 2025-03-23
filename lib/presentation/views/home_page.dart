// lib/presentation/views/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';

// Widgets y barras
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;
import 'package:senemarket/presentation/widgets/global/filter_bar.dart';

// ViewModel para la búsqueda

// Tarjeta de producto que ahora espera un `Product`
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';

// Constantes (categorías, colores, etc.)
import 'package:senemarket/constants.dart' as constants;

// Entidad de dominio
import 'package:senemarket/domain/entities/product.dart';

// Repositorio (aún lo instanciamos localmente,
// aunque lo ideal es usar Provider para inyectarlo)
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

  // Mapa para conteo de clics por categoría
  Map<String, int> _categoryClicks = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Aquí instanciamos el ProductRepository.
  // (Ideal: usar un Provider<ProductRepository> en main.dart)
  final _productRepo = ProductRepositoryImpl();

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
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add_product');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }


  /// Incrementa y persiste el contador de clics de una categoría.
  void _incrementCategoryClick(String category) async {
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
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

  /// Filtra los productos según el query del ViewModel y las categorías seleccionadas.
  List<Product> _filterProducts(
      List<Product> baseProducts,
      ProductSearchViewModel searchViewModel,
      ) {
    final searchQuery = searchViewModel.searchQuery;

    // Si hay un query, usamos los resultados del ViewModel (Algolia); si no, baseProducts.
    final List<Product> products = searchQuery.isNotEmpty
        ? searchViewModel.searchResults
        : baseProducts;

    // Si no hay categorías seleccionadas, devolvemos tal cual.
    if (_selectedCategories.isEmpty) {
      return products;
    }

    // De lo contrario, filtramos por categoría
    return products.where((product) {
      final productCategory = product.category.toLowerCase();
      return _selectedCategories.any(
            (selected) => productCategory.contains(selected.toLowerCase()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ProductSearchViewModel para el query
    final productSearchViewModel = context.watch<ProductSearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda
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

            // Barra de filtros
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

            // StreamBuilder con ProductRepository para mostrar los productos
            Expanded(
              child: StreamBuilder<List<Product>>(
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

                  // Todos los productos provenientes de Firestore
                  final allProducts = snapshot.data!;

                  // Aplicar el filtrado por query y categorías
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
      ),
    );
  }
}
