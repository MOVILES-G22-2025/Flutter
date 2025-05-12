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
  String? _smartRecommendedCategory;
  List<Product>? _allProducts;

  // For the recommended carousel
  final PageController _recController = PageController(viewportFraction: 0.8);
  int _currentRecPage = 0;
  bool _showRecommended = true;

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final _productRepo = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();
    // kick off an empty search so that Algolia results reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductSearchViewModel>().updateSearchQuery('');
    });
    _loadUserClicks();
    _loadSmartRecommendationByHour();
    _listenToProducts();
  }

  @override
  void dispose() {
    _recController.dispose();
    super.dispose();
  }

  Future<void> _listenToProducts() async {
    _productRepo.getProductsStream().listen((products) {
      setState(() => _allProducts = products);
    });
  }

  Future<void> _loadUserClicks() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      setState(() {
        _categoryClicks =
        Map<String, int>.from(doc.data()?['categoryClicks'] ?? {});
      });
    }
  }

  Future<void> _loadSmartRecommendationByHour() async {
    final hour = DateTime.now().hour;
    final docId = 'hour_$hour';
    final snap = await FirebaseFirestore.instance
        .collection('product-clics')
        .doc(docId)
        .get();
    if (!snap.exists) return;
    final cats = Map<String, dynamic>.from(snap.data()?['categories'] ?? {});
    if (cats.isEmpty) return;
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    setState(() => _smartRecommendedCategory = sorted.first.key);
  }

  Future<void> _registerProductClick(Product p) async {
    final hour = DateTime.now().hour;
    final docId = 'hour_$hour';
    final ref = FirebaseFirestore.instance.collection('product-clics').doc(docId);
    try {
      await ref.set({
        'totalClicks': FieldValue.increment(1),
        'categories': {p.category: FieldValue.increment(1)},
        'hour': hour,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating clicks: $e');
    }
  }

  void _onItemTapped(int idx) {
    if (idx == _selectedIndex) return;
    setState(() => _selectedIndex = idx);
    switch (idx) {
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

  void _incrementCategoryClick(String cat) async {
    setState(() => _categoryClicks[cat] = (_categoryClicks[cat] ?? 0) + 1);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
      'categoryClicks': {cat: FieldValue.increment(1)}
    }, SetOptions(merge: true));
  }

  List<String> get _categoriesSortedByClicks {
    final all = constants.ProductClassification.categories;
    final sorted = all.toList()
      ..sort((a, b) => (_categoryClicks[b] ?? 0).compareTo(_categoryClicks[a] ?? 0));
    return sorted;
  }

  List<Product> _filterProducts(
      List<Product> base, ProductSearchViewModel vm) {
    final query = vm.searchQuery;
    final List<Product> source =
    query.isNotEmpty ? vm.searchResults : base;
    // exclude own products
    final visible = source.where((p) => p.userId != userId).toList();
    // category filter
    final filtered = _selectedCategories.isEmpty
        ? visible
        : visible.where((p) {
      final lc = p.category.toLowerCase();
      return _selectedCategories.any((sel) =>
          lc.contains(sel.toLowerCase()));
    }).toList();
    // sort by date
    filtered.sort((a, b) {
      final ta = a.timestamp, tb = b.timestamp;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return _sortOrder == 'Newest first'
          ? tb.compareTo(ta)
          : ta.compareTo(tb);
    });
    // sort by price
    if (_sortPrice != null) {
      filtered.sort((a, b) => _sortPrice == 'Price: Low to High'
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = context.watch<ProductSearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── Search + Cart row ──
              Row(
                children: [
                  Expanded(
                    child: searchBar.SearchBar(
                      hintText: 'Search products...',
                      onChanged: searchVM.updateSearchQuery,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    color: Colors.black,
                    iconSize: 28,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/cart'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Filter bar ──
              FilterBar(
                categories: _categoriesSortedByClicks,
                selectedCategories: _selectedCategories,
                onCategoriesSelected: (sel) =>
                    setState(() => _selectedCategories = sel),
                onSortByDateSelected: (o) =>
                    setState(() => _sortOrder = o),
                onSortByPriceSelected: (o) =>
                    setState(() => _sortPrice = o),
                onAcademicCalendarSelected: (b) =>
                    setState(() => _academicCalendarActive = b),
              ),
              const SizedBox(height: 16),
              // ── Recommended carousel ──
              if (_smartRecommendedCategory != null &&
                  _selectedCategories.isEmpty &&
                  _allProducts != null)
                _buildSmartRecommendationSection(),
              // ── Main grid ──
              if (_allProducts == null)
                const Center(child: CircularProgressIndicator())
              else
                _buildMainProductGrid(searchVM),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
      ),
    );
  }

  Widget _buildSmartRecommendationSection() {
    final recs = _allProducts!
        .where((p) =>
    p.category.toLowerCase() ==
        _smartRecommendedCategory!
            .toLowerCase() &&
        p.userId != userId)
        .toList();
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended now',
              style: TextStyle(
                fontFamily: 'Cabin',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                _showRecommended
                    ? Icons.expand_less
                    : Icons.expand_more,
              ),
              onPressed: () => setState(
                      () => _showRecommended = !_showRecommended),
            ),
          ],
        ),
        if (_showRecommended) ...[
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _recController,
              itemCount: recs.length,
              onPageChanged: (i) =>
                  setState(() => _currentRecPage = i),
              itemBuilder: (ctx, i) {
                final p = recs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0),
                  child: GestureDetector(
                    onTap: () => _registerProductClick(p),
                    child: ProductCard(
                      product: p,
                      onCategoryTap: _incrementCategoryClick,
                      onProductTap: () =>
                          _registerProductClick(p), originIndex: 0,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Dots indicator
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: List.generate(
              recs.length,
                  (i) => AnimatedContainer(
                duration:
                const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(
                    horizontal: 4),
                width: _currentRecPage == i ? 12 : 8,
                height: _currentRecPage == i ? 12 : 8,
                decoration: BoxDecoration(
                  color: _currentRecPage == i
                      ? constants
                      .AppColors.primary30
                      : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildMainProductGrid(
      ProductSearchViewModel vm) {
    final filtered = _filterProducts(
        _allProducts!, vm);
    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (ctx, idx) {
        final p = filtered[idx];
        return ProductCard(
          product: p,
          onCategoryTap: _incrementCategoryClick,
          onProductTap: () => _registerProductClick(p),
          originIndex: 0,
        );
      },
    );
  }
}
