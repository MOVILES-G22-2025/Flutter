import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/global/navigation_bar.dart';
import 'viewmodel/favorites_viewmodel.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';

/// UI page that displays the current user's favorite products.
/// Uses FavoritesViewModel for state and logic.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    // Loads the favorites after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesViewModel>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavoritesViewModel>();
    final favorites = viewModel.favorites;

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button
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
          // Sort toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    color: AppColors.primary30,
                  ),
                ),
              ),
            ),
          ),
          // Product list
          Expanded(
            child: favorites.isEmpty
                ? const Center(
              child: Text(
                "No favorites yet.",
                style: TextStyle(fontFamily: 'Cabin', fontSize: 16),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                return ProductCard(product: favorites[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
