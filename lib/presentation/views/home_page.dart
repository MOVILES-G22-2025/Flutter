import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';

// UI components
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;
import 'package:senemarket/presentation/widgets/global/filter_bar.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';

// Constants and data
import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';

/// Home page that displays product grid, search bar and filters
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Sort settings
  String _sortOrder = 'Newest first';
  String? _sortPrice;

  // Selected categories for filtering
  List<String> _selectedCategories = [];

  // Tracks category clicks for sorting
  Map<String, int> _categoryClicks = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final _productRepo = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();

    // Reinicia el query de búsqueda cuando se entra al Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVM = context.read<ProductSearchViewModel>();
      searchVM.updateSearchQuery('');
    });

    _loadUserClicks();
  }

  /// Load category click data from Firestore
  Future<void> _loadUserClicks() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      setState(() {
        _categoryClicks = Map<String, int>.from(data?['categoryClicks'] ?? {});
      });
    }
  }

  /// Handles tap on bottom navigation bar
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/home'); break;
      case 1: Navigator.pushReplacementNamed(context, '/chats'); break;
      case 2: Navigator.pushReplacementNamed(context, '/add_product'); break;
      case 3: Navigator.pushReplacementNamed(context, '/favorites'); break;
      case 4: Navigator.pushReplacementNamed(context, '/profile'); break;
    }
  }

  /// Increment category click count and save to Firestore
  void _incrementCategoryClick(String category) async {
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  /// Return categories sorted by user's clicks
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

  /// Filter and sort the products
  List<Product> _filterProducts(
      List<Product> baseProducts,
      ProductSearchViewModel searchViewModel,
      ) {
    final searchQuery = searchViewModel.searchQuery;

    // Use Algolia results if query exists
    final List<Product> products = searchQuery.isNotEmpty
        ? searchViewModel.searchResults
        : baseProducts;

    // Exclude products created by the current user
    final visibleProducts = products.where((product) => product.userId != userId).toList();

    // Filter by selected categories
    List<Product> filtered = _selectedCategories.isEmpty
        ? visibleProducts
        : visibleProducts.where((product) {
      final productCategory = product.category.toLowerCase();
      return _selectedCategories.any((selected) =>
          productCategory.contains(selected.toLowerCase()));
    }).toList();

    // Sort by date
    filtered.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;

      return _sortOrder == 'Newest first'
          ? b.timestamp!.compareTo(a.timestamp!)
          : a.timestamp!.compareTo(b.timestamp!);
    });

    // Optional: sort by price if selected
    if (_sortPrice != null) {
      filtered.sort((a, b) {
        return _sortPrice == 'Price: Low to High'
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price);
      });
    }

    return filtered;
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
            // Search input
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

            // Filter bar
            FilterBar(
              categories: _categoriesSortedByClicks,
              selectedCategories: _selectedCategories,
              onCategoriesSelected: (selected) {
                setState(() {
                  _selectedCategories = selected;
                });
              },
              onSortByDateSelected: (selectedOrder) {
                setState(() {
                  _sortOrder = selectedOrder;
                });
              },
              onSortByPriceSelected: (selectedOrder) {
                setState(() {
                  _sortPrice = selectedOrder;
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Product grid
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
      ),
    );
  }
}
