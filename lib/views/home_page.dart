import 'package:flutter/material.dart';
import '../common/navigation_bar.dart';
import '../views/product_view/add_product_page.dart';
import '../views/product_view/product_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _addedProducts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newProduct =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (newProduct != null) {
      _onProductAdded(newProduct);
    }
  }

  void _onProductAdded(Map<String, dynamic> product) {
    setState(() {
      _addedProducts.add(product);
    });
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      final newProduct = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddProductPage()),
      );

      if (newProduct != null && newProduct is Map<String, dynamic>) {
        _onProductAdded(newProduct);
        setState(() {
          _selectedIndex = 0;
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _addedProducts.isEmpty
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _addedProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: _addedProducts[index]);
                },
              ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
