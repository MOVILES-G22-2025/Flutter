// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/chats_page.dart';
import 'pages/sell_page.dart';
import 'pages/favorites_page.dart';
import 'pages/profile_page.dart';
import 'common/navigation_bar.dart';
import 'constants.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas, donde el HomePage es el primer tab.
  final List<Widget> _screens = [
    const HomePage(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pantalla.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
