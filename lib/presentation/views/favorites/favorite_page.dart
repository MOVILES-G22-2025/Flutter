// lib/presentation/views/favorites/favorite_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';

import '../../../../constants.dart';
import '../../../../domain/entities/product.dart';
import '../../../../presentation/widgets/global/navigation_bar.dart';
import '../../../../presentation/widgets/global/search_bar.dart' as searchBar;
import '../../../core/services/custom_cache_manager.dart';
import '../products/product_detail_page.dart';
import '../products/widgets/product_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const int _navIndex = 3;
  String _searchQuery = '';
  bool _isGrid = true; // para toggle Grid/List
  final TextEditingController _searchController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesViewModel>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _registerProductClick(Product product) async {
    final hour = DateTime.now().hour;
    final docId = 'hour_$hour';
    final category = product.category;
    try {
      await FirebaseFirestore.instance
          .collection('product-clics')
          .doc(docId)
          .set({
        'totalClicks': FieldValue.increment(1),
        'categories': {category: FieldValue.increment(1)},
        'hour': hour,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error actualizando clics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    final allFavs = vm.favorites;

    // Filtrado local
    final filtered = allFavs.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const Text(
              'Favorites',
              style: TextStyle(
                fontFamily: 'Cabin',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary0,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: _navIndex),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: searchBar.SearchBar(
              controller: _searchController,
              hintText: 'Search in favorites...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          // ── Toggle Grid/List + Orden ──
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Toggle Grid/List
                IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    color:
                    _isGrid ? AppColors.primary30 : Colors.grey[400],
                  ),
                  onPressed: () => setState(() => _isGrid = true),
                ),
                IconButton(
                  icon: Icon(
                    Icons.view_list,
                    color:
                    !_isGrid ? AppColors.primary30 : Colors.grey[400],
                  ),
                  onPressed: () => setState(() => _isGrid = false),
                ),
                const Spacer(),
                // Toggle orden
                TextButton.icon(
                  onPressed: vm.toggleOrder,
                  icon: const Icon(Icons.swap_vert,
                      color: AppColors.primary30),
                  label: Text(
                    vm.showRecentFirst ? 'Newest' : 'Oldest',
                    style: const TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Contenido ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : _isGrid
                ? _buildGrid(filtered)
                : _buildList(filtered), // <-- ahora lista
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Still no favorites",
            style: TextStyle(
              fontFamily: 'Cabin',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary30,
              foregroundColor: AppColors.primary0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Explore products'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (ctx, i) {
        final prod = products[i];
        return ProductCard(
          product: prod,
          originIndex: _navIndex,
          onCategoryTap: (_) {},
          onProductTap: () {
            _registerProductClick(prod);
          },
        );
      },
    );
  }

  Widget _buildList(List<Product> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final prod = products[i];
        return ListTile(
          contentPadding: const EdgeInsets.all(8),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: AspectRatio(
            aspectRatio: 1,
            child: prod.imageUrls.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: prod.imageUrls.first,
              cacheManager: CustomCacheManager.instance,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
                : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          title: Text(
            prod.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cabin',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '\$${prod.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
          onTap: () {
            // 1) registro click
            _registerProductClick(prod);
            // 2) navego al detalle
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(
                  product: prod,
                  originIndex: _navIndex,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
