import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    Key? key,
    required this.controller,
    required this.label,
    this.onChanged,
  }) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _passwordVisible = false;
  bool _hasMinLength = false;
  bool _hasNumbers = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasSpecialChar = false;

  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasNumbers = RegExp(r'(?:.*\d.*\d)').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    });

    if (widget.onChanged != null) {
      widget.onChanged!(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: !_passwordVisible,
          onChanged: _validatePassword,
          style: const TextStyle(
            fontFamily: 'Cabin',
            fontSize: 16,
            color: AppColors.primary0,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: AppColors.secondary60,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primary30,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.secondary60),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary30, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildValidationRow('At least 8 characters', _hasMinLength),
        _buildValidationRow('At least 2 numbers', _hasNumbers),
        _buildValidationRow('At least 1 uppercase letter', _hasUppercase),
        _buildValidationRow('At least 1 lowercase letter', _hasLowercase),
        _buildValidationRow('At least 1 special character', _hasSpecialChar),
      ],
    );
  }

  Widget _buildValidationRow(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel,
            color: valid ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cabin',
              fontSize: 14,
              color: valid ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
