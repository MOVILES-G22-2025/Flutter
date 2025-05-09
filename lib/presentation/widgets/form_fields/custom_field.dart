// lib/presentation/widgets/form_fields/custom_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senemarket/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumeric;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator; // ← añadido

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.isNumeric = false,
    this.onChanged,
    this.focusNode,
    this.validator, // ← añadido
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(  // ← TextFormField en lugar de TextField
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
        isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(
          fontFamily: 'Cabin',
          fontSize: 16,
          color: AppColors.primary0,
        ),
        onChanged: onChanged,
        validator: validator,  // ← pasamos validator
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          filled: true,
          fillColor: AppColors.secondary60,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.secondary60, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.secondary60, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.primary30, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}
