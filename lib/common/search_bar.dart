// lib/common/widgets/search_bar.dart
import 'package:flutter/material.dart';

import '../constants.dart';

class SearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          // Cuando se hace click (tiene foco), se llena de color; de lo contrario, es transparente
          filled: _isFocused,
          fillColor: _isFocused ? AppColors.primary30 : Colors.transparent,
          // Borde normal
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(50.0),
          ),
          // Borde cuando se hace click
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors
                  .primary30, // Puedes cambiar este color según tu diseño
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(50.0),
          ),
          // Icono de lupa a la derecha
          suffixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}
