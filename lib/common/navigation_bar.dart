import 'package:flutter/material.dart';
import '../constants.dart';

class NavigationBarApp extends StatefulWidget {
  final ValueChanged<int> onItemTapped;
  final int selectedIndex;

  const NavigationBarApp({
    super.key,
    required this.onItemTapped,
    required this.selectedIndex,
  });

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

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
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
          icon: _buildStaticSellIcon(Icons.file_upload_outlined, 'Sell', 2),
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
      currentIndex: _validateIndex(widget.selectedIndex),
      onTap: (index) {
        _navigateToPage(index, context);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary40,
      selectedItemColor: AppColors.primary0,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Cabin',
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Cabin',
        fontSize: 12,
      ),
    );
  }

  void _navigateToPage(int index, BuildContext context) {
    if (index == widget.selectedIndex) return;

    switch (index) {
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

  Widget _buildIcon(IconData icon, int index) {
    bool isSelected = widget.selectedIndex == index;
    IconData displayIcon = isSelected && _filledIconMapping.containsKey(icon)
        ? _filledIconMapping[icon]!
        : icon;
    Color iconColor = isSelected ? AppColors.primary30 : AppColors.primary0;

    return Icon(
      displayIcon,
      color: iconColor,
    );
  }

  Widget _buildStaticSellIcon(IconData icon, String label, int index) {
    bool isSelected = widget.selectedIndex == index;

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary50,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.primary30,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary0,
              size: 28,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cabin',
                color: AppColors.primary0,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
