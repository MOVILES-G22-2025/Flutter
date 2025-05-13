import 'package:flutter/material.dart';
import '../../../constants.dart';

class SearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchBar({
    Key? key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _internalController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _clearText() {
    _internalController.clear();
    widget.onChanged?.call('');
    FocusScope.of(context).requestFocus(_focusNode); // Retiene el teclado
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _internalController,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: _isFocused,
        fillColor: _isFocused ? AppColors.primary30 : Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(30.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary20, width: 2.0),
          borderRadius: BorderRadius.circular(100.0),
        ),
        suffixIcon: _internalController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearText,
        )
            : const Icon(Icons.search),
      ),
    );
  }
}