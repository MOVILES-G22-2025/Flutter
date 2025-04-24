import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;
import 'package:senemarket/presentation/widgets/global/filter_bar.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';
import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _sortOrder = 'Newest first';
  String? _sortPrice;
  List<String> _selectedCategories = [];
  Map<String, int> _categoryClicks = {};
  bool _academicCalendarActive = false;
  String? _featuredCategory;
  String? _smartRecommendedCategory;
  List<Product>? _allProducts;

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final _productRepo = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVM = context.read<ProductSearchViewModel>();
      searchVM.updateSearchQuery('');
    });

    _loadUserClicks();
    _loadSmartRecommendationByHour();
    _listenToProducts();
  }

  Future<void> _listenToProducts() async {
    _productRepo.getProductsStream().listen((products) {
      setState(() {
        _allProducts = products;
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

  Future<void> _loadSmartRecommendationByHour() async {
    final now = DateTime.now();
    final currentHour = now.hour;
    final docId = "hour_$currentHour";

    final docRef = FirebaseFirestore.instance.collection("product-clics").doc(docId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data();
    final categories = Map<String, dynamic>.from(data?['categories'] ?? {});

    if (categories.isEmpty) return;

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _smartRecommendedCategory = sorted.first.key;
    });
  }

  Future<void> _registerProductClick(Product product) async {
    final hour = DateTime.now().hour;
    final docId = 'hour_$hour';
    final category = product.category;

    final docRef = FirebaseFirestore.instance.collection('product-clics').doc(docId);

    try {
      await docRef.set({
        'totalClicks': FieldValue.increment(1),
        'categories': {category: FieldValue.increment(1)},
        'hour': hour,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error actualizando clics: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
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

  void _incrementCategoryClick(String category) async {
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

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

  List<Product> _filterProducts(List<Product> baseProducts, ProductSearchViewModel searchViewModel) {
    final searchQuery = searchViewModel.searchQuery;
    final List<Product> products = searchQuery.isNotEmpty
        ? searchViewModel.searchResults
        : baseProducts;

    final visibleProducts = products.where((p) => p.userId != userId).toList();

    List<Product> filtered = _selectedCategories.isEmpty
        ? visibleProducts
        : visibleProducts.where((product) {
      final productCategory = product.category.toLowerCase();
      return _selectedCategories.any((selected) =>
          productCategory.contains(selected.toLowerCase()));
    }).toList();

    filtered.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return _sortOrder == 'Newest first'
          ? b.timestamp!.compareTo(a.timestamp!)
          : a.timestamp!.compareTo(b.timestamp!);
    });

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36.0),
            searchBar.SearchBar(
              hintText: 'Search products...',
              onChanged: (value) {
                productSearchViewModel.updateSearchQuery(value);
              },
            ),
            const SizedBox(height: 16.0),
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
              onAcademicCalendarSelected: (bool isActive) {
                setState(() {
                  _academicCalendarActive = isActive;
                });
              },
            ),
            const SizedBox(height: 16.0),
            if (_smartRecommendedCategory != null &&
                _selectedCategories.isEmpty &&
                _allProducts != null)
              _buildSmartRecommendationSection(),
            if (_allProducts == null)
              const Center(child: CircularProgressIndicator())
            else
              _buildMainProductGrid(productSearchViewModel),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
      ),
    );
  }

  Widget _buildSmartRecommendationSection() {
    final recommendedProducts = _allProducts!
        .where((p) =>
    p.category.toLowerCase() == _smartRecommendedCategory!.toLowerCase() &&
        p.userId != userId)
        .take(4)
        .toList();

    if (recommendedProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFF5C508)),
              const SizedBox(width: 8),
              const Text(
                'Recommended now:',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _smartRecommendedCategory!,
            style: const TextStyle(
              fontFamily: 'Cabin',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendedProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final product = recommendedProducts[index];
              return ProductCard(
                product: product,
                onCategoryTap: (category) => _incrementCategoryClick(category),
                onProductTap: () => _registerProductClick(product),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainProductGrid(ProductSearchViewModel searchVM) {
    final filteredProducts = _filterProducts(_allProducts!, searchVM);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(
          product: product,
          onCategoryTap: (category) => _incrementCategoryClick(category),
          onProductTap: () => _registerProductClick(product),
        );
      },
    );
  }
}

