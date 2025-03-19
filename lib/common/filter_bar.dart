import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

class FilterBar extends StatefulWidget {
  /// Lista de categorias a mostrar.
  final List<String> categories;

  final List<String>? selectedCategories;

  /// Callback que se dispara cuando se seleccionan/deseleccionan categorias.
  final ValueChanged<List<String>> onCategoriesSelected;

  const FilterBar({
    Key? key,
    required this.categories,
    this.selectedCategories,
    required this.onCategoriesSelected,
  }) : super(key: key);

  @override
  _FilterBarState createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.selectedCategories != null
        ? widget.selectedCategories!.toSet()
        : <String>{};
  }

  void _toggleSelection(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    widget.onCategoriesSelected(_selectedCategories.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // icono de filtro
        Icon(
          Icons.filter_list_rounded,
          size: 30,
          color: Colors.black,
        ),
        const SizedBox(width: 8),
        // Lista horizontal de categorías
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories.map((category) {
                final bool isSelected = _selectedCategories.contains(category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _toggleSelection(category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary30 : Colors.grey,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Indicador estilo "checkbox" (círculo)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary30 : Colors.grey,
                              ),
                            ),
                            child: isSelected
                                ? Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary30,
                              ),
                            )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'Cabin',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
