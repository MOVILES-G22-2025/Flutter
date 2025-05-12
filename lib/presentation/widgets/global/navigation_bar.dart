import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';

import '../../views/chat/viewmodel/chat_list_viewmodel.dart';

class NavigationBarApp extends StatefulWidget {
  final int selectedIndex;

  const NavigationBarApp({
    Key? key,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _NavigationBarAppState createState() => _NavigationBarAppState();
}

class _NavigationBarAppState extends State<NavigationBarApp> {
  final Map<IconData, IconData> _filledIconMapping = {
    Icons.home_outlined: Icons.home,
    Icons.chat_bubble_outline_rounded: Icons.chat_bubble,
    Icons.favorite_border: Icons.favorite,
    Icons.person_outline: Icons.person,
  };

  int _validateIndex(int index) {
    return (index >= 0 && index < 5) ? index : 0;
  }

  void _navigateToPage(int index) {
    if (index == widget.selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/chats');
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary40,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            elevation: 0,
            currentIndex: _validateIndex(widget.selectedIndex),
            onTap: _navigateToPage,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary30,
            unselectedItemColor: AppColors.primary0,
            selectedLabelStyle: const TextStyle(
                fontFamily: 'Cabin', fontSize: 12),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cabin', fontSize: 12),
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.home_outlined, 0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.chat_bubble_outline_rounded, 1),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: _buildSellIcon(2),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.favorite_border, 3),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.person_outline, 4),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    final unread = context
        .watch<ChatListViewModel>()
        .totalUnreadChats;
    final isSelected = widget.selectedIndex == index;
    final finalIcon = isSelected && _filledIconMapping.containsKey(icon)
        ? _filledIconMapping[icon]!
        : icon;

    Widget iconWidget = Icon(
      finalIcon,
      size: 26,
      color: isSelected ? AppColors.primary30 : AppColors.primary0,
    );

    // Solo mostrar badge si es el ícono de chats
    if (index == 1 && unread > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }

  Widget _buildSellIcon(int index) {
    bool isSelected = widget.selectedIndex == index;

    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: AppColors.primary30, width: 2),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_upload_outlined, color: AppColors.primary0,
                size: 26),
            SizedBox(height: 2),
            Text(
              'Sell',
              style: TextStyle(
                fontFamily: 'Cabin',
                color: AppColors.primary0,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}