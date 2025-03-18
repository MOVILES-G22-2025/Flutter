import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/navigation_bar.dart';
import '../views/product_view/product_card.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Map<String, dynamic>> _addedProducts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FirebaseFirestore.instance
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      List<Map<String, dynamic>> products = [];
      querySnapshot.docs.forEach((doc) {
        products.add(doc.data());
      });

      setState(() {
        _addedProducts = products;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                  crossAxisCount: 2, // 📌 Dos columnas
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
