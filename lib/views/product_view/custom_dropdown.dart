import 'package:flutter/material.dart';
import '../../constants.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        dropdownColor: AppColors.primary50,
        value: selectedItem,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Cabin',
          fontSize: 16,
          color: AppColors.primary0,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'Cabin',
            fontSize: 16,
            color: AppColors.secondary30,
          ),
          filled: true,
          fillColor: AppColors.secondary60,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.secondary60,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.secondary60,
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.secondary60,
              width: 2.0,
            ),
          ),
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}
