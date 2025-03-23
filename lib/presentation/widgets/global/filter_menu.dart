import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

class FilterMenu extends StatelessWidget {
  final String selectedDateOrder;
  final String selectedPriceOrder;
  final Function(String) onDateSortSelected;
  final Function(String) onPriceSortSelected;

  const FilterMenu({
    Key? key,
    required this.selectedDateOrder,
    required this.selectedPriceOrder,
    required this.onDateSortSelected,
    required this.onPriceSortSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.secondary70, // Fondo naranja
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SectionTitle(title: 'Sort by date'),
            _buildOption(
              context,
              label: 'Newest first',
              icon: Icons.access_time,
              isSelected: selectedDateOrder == 'Newest first',
              onTap: onDateSortSelected,
            ),
            _buildOption(
              context,
              label: 'Oldest first',
              icon: Icons.history,
              isSelected: selectedDateOrder == 'Oldest first',
              onTap: onDateSortSelected,
            ),
            const Divider(color: AppColors.primary30, thickness: 1, height: 24),
            const _SectionTitle(title: 'Sort by price'),
            _buildOption(
              context,
              label: 'Price: High to Low',
              icon: Icons.trending_down,
              isSelected: selectedPriceOrder == 'Price: High to Low',
              onTap: onPriceSortSelected,
            ),
            _buildOption(
              context,
              label: 'Price: Low to High',
              icon: Icons.trending_up,
              isSelected: selectedPriceOrder == 'Price: Low to High',
              onTap: onPriceSortSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool isSelected,
        required Function(String) onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary30),
      title: Text(
        label,
        style: const TextStyle(fontFamily: 'Cabin', color: Colors.black),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
      onTap: () {
        onTap(label);
        Navigator.pop(context);
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cabin',
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
