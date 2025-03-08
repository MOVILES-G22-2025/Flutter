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
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.home, 0),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.chat, 1),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: _buildStaticSellIcon(Icons.upload, 'Sell', 2),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.star, 3),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: _buildIcon(Icons.person, 4),
          label: 'Profile',
        ),
      ],
      currentIndex: widget.selectedIndex,
      selectedItemColor: AppColors.primary0,
      unselectedItemColor: AppColors.primary0,
      onTap: widget.onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary40,
      selectedFontSize: 12,
      unselectedFontSize: 12,
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    bool isSelected = widget.selectedIndex == index;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary50 : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected ? AppColors.primary0 : AppColors.primary0,
      ),
    );
  }

  Widget _buildStaticSellIcon(IconData icon, String label, int index) {
    return Container(
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
              color: AppColors.primary0,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
