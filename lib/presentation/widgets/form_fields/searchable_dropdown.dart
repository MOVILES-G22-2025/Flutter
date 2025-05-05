// lib/presentation/widgets/form_fields/searchable_dropdown.dart

import 'package:flutter/material.dart';
import 'package:senemarket/constants.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onChanged;

  const SearchableDropdown({
    Key? key,
    required this.label,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  }) : super(key: key);

  @override
  _SearchableDropdownState createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  late TextEditingController _searchController;
  late List<String> _filteredItems;
  String? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedItem;
    _filteredItems = List.from(widget.items);
    _searchController = TextEditingController(text: widget.selectedItem ?? '');
  }

  Future<void> _openSearchModal() async {
    // Inicializar filtro
    _searchController.text = '';
    _filteredItems = List.from(widget.items);

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, modalSetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Título
                Text(
                  'Select ${widget.label}',
                  style: const TextStyle(
                    fontFamily: 'Cabin',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Campo de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.label}',
                      filled: true,
                      fillColor: AppColors.secondary60,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondary60),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondary60),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary30, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onChanged: (q) {
                      modalSetState(() {
                        _filteredItems = widget.items
                            .where((it) => it.toLowerCase().contains(q.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Lista filtrada
                SizedBox(
                  height: 300,
                  child: _filteredItems.isEmpty
                      ? Center(
                    child: Text(
                      'No ${widget.label.toLowerCase()} found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.separated(
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = _filteredItems[i];
                      final isSelected = it == _currentSelection;
                      return ListTile(
                        title: Text(
                          it,
                          style: TextStyle(
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary30)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx, it);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );

    if (selected != null && selected != _currentSelection) {
      setState(() {
        _currentSelection = selected;
      });
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: _openSearchModal,
        child: AbsorbPointer(
          child: TextFormField(
            controller: TextEditingController(text: _currentSelection ?? ''),
            decoration: InputDecoration(
              labelText: widget.label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              filled: true,
              fillColor: AppColors.secondary60,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.secondary60),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.secondary60),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary30, width: 2),
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }
}
