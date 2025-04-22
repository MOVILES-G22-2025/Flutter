import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/favorites/viewmodel/favorites_viewmodel.dart';

import '../../widgets/global/navigation_bar.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final int _selectedIndex = 3;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Se asume que el usuario está autenticado en esta página.
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesViewModel>(context, listen: false).loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _registerProductClick(dynamic product) async {
    final hour = DateTime.now().hour; // Hora actual (0-23)
    final docId = 'hour_$hour';
    final category = product.category;

    final docRef = FirebaseFirestore.instance.collection('product-clics').doc(docId);

    try {
      await docRef.set({
        'totalClicks': FieldValue.increment(1),
        'categories': {
          category: FieldValue.increment(1),
        },
        'hour': hour, // útil por si deseas filtrar posteriormente
        'lastUpdated': FieldValue.serverTimestamp(), // opcional pero útil
      }, SetOptions(merge: true));

      print('Registrado clic en hora: $hour, categoría: $category');
    } catch (e) {
      print('Error actualizando clics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavoritesViewModel>();
    final favorites = viewModel.favorites;

    final filteredFavorites = favorites.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary0,
          ),
        ),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 3),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: searchBar.SearchBar(
              controller: _searchController,
              hintText: 'Search favorites...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  context.read<FavoritesViewModel>().toggleOrder();
                },
                icon: const Icon(Icons.swap_vert, color: AppColors.primary30),
                label: Text(
                  viewModel.showRecentFirst ? 'Most Recent' : 'Oldest First',
                  style: const TextStyle(
                    fontFamily: 'Cabin',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary0,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredFavorites.isEmpty
                ? const Center(
              child: Text(
                "No favorites found.",
                style: TextStyle(fontFamily: 'Cabin', fontSize: 16),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFavorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final product = filteredFavorites[index];
                return ProductCard(
                  product: product,
                  onCategoryTap: (category) {
                    // Aquí puedes dejar la lógica de incrementar clics de categoría
                  },
                  // Se agrega el callback para registrar el clic del producto.
                  onProductTap: () {
                    _registerProductClick(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

