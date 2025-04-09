import 'package:flutter/material.dart';
import '../../../constants.dart';          // Asegúrate de que sea la ruta correcta
import 'filter_menu.dart';

class FilterBar extends StatefulWidget {
  // Lista de categorías disponibles
  final List<String> categories;
  // Categorías seleccionadas
  final List<String>? selectedCategories;

  // Callbacks existentes para ordenar por fecha/precio
  final ValueChanged<String>? onSortByDateSelected;
  final ValueChanged<String>? onSortByPriceSelected;

  // Callback cuando cambia la selección de categorías
  final ValueChanged<List<String>> onCategoriesSelected;

  // NUEVO: Callback para avisar si se activó/desactivó el “Academic Calendar”
  final ValueChanged<bool>? onAcademicCalendarSelected;

  const FilterBar({
    Key? key,
    required this.categories,
    this.selectedCategories,
    required this.onCategoriesSelected,
    this.onSortByDateSelected,
    this.onSortByPriceSelected,
    // nuevo
    this.onAcademicCalendarSelected,
  }) : super(key: key);

  @override
  _FilterBarState createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late Set<String> _selectedCategories;
  String _selectedDateOrder = 'Newest first';
  String _selectedPriceOrder = 'Price: Low to High';

  // NUEVO: guardamos el estado de Academic Calendar
  bool _isAcademicCalendarActive = false;

  @override
  void initState() {
    super.initState();
    // Si ya vienen categorías seleccionadas, las guardamos en el set
    _selectedCategories = widget.selectedCategories?.toSet() ?? <String>{};
  }

  /// Agrega o quita la categoría del set de seleccionadas
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

  /// Abre el menú de filtros (sort by date/price) y academic calendar
  void _openFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return FilterMenu(
          selectedDateOrder: _selectedDateOrder,
          selectedPriceOrder: _selectedPriceOrder,
          onDateSortSelected: (selectedOrder) {
            setState(() {
              _selectedDateOrder = selectedOrder;
            });
            // Notificamos al padre si hace falta
            widget.onSortByDateSelected?.call(selectedOrder);
          },
          onPriceSortSelected: (selectedOrder) {
            setState(() {
              _selectedPriceOrder = selectedOrder;
            });
            // Notificamos al padre si hace falta
            widget.onSortByPriceSelected?.call(selectedOrder);
          },
          // Pasamos el estado del academic calendar
          academicCalendarActive: _isAcademicCalendarActive,
          // Al togglear, actualizamos el estado local y avisamos al padre
          onAcademicCalendarToggle: (newValue) {
            setState(() {
              _isAcademicCalendarActive = newValue;
            });
            widget.onAcademicCalendarSelected?.call(newValue);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícono que abre el bottom sheet de filtros
        GestureDetector(
          onTap: _openFilterMenu,
          child: const Icon(
            Icons.filter_list_rounded,
            size: 30,
            color: Colors.black,
          ),
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
                          color:
                          isSelected ? AppColors.primary30 : Colors.grey,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Círculo interior que se rellena o no, según la selección
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary30
                                    : Colors.grey,
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
                          // Texto de la categoría
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
