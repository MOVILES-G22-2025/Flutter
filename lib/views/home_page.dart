import 'package:flutter/material.dart';
import '../common/navigation_bar.dart';
import '../views/product_view/add_product_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const Center(
        child: Text('Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(
        child: Text('Chats Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(
        child: Text('Favorites Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(
        child: Text('Profile Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddProductPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
