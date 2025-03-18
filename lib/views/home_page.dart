import 'package:flutter/material.dart';
import '../common/navigation_bar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    Center(
        child: Text('Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(
        child: Text('Chats Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(
        child: Text('Sell Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(
        child: Text('Favorites Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(
        child: Text('Profile Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SeneMarket'),
        backgroundColor: Colors.yellow,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}