import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants.dart';
import '../../../presentation/views/products/viewmodel/product_search_viewmodel.dart';

class SearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBar({
    Key? key,
    this.hintText = 'Search...',
    this.onChanged,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;

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

  void _clearText(BuildContext context) {
    _controller.clear();
    widget.onChanged?.call('');
    context.read<ProductSearchViewModel>().clearSearch(); // <- clave
    FocusScope.of(context).unfocus(); // cierra el teclado si está activo
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: _isFocused,
        fillColor: _isFocused ? AppColors.primary20 : Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(30.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: AppColors.primary20,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(100.0),
        ),
        // Muestra una "X" si hay texto, si no muestra el ícono de búsqueda
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _clearText(context),
        )
            : const Icon(Icons.search),
      ),
    );
  }
}
