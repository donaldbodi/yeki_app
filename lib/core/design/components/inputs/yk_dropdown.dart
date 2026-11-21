import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../feedback/yk_skeleton.dart';

class YkDropdownItem<T> {
  const YkDropdownItem({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Liste déroulante générique — CDC_DESIGN §5.3.2. Recherche intégrée
/// automatiquement au-delà de 10 items (`DropdownMenu.enableFilter`,
/// widget Material natif — pas de recherche/filtre réécrite à la main).
class YkDropdown<T> extends StatelessWidget {
  const YkDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.label,
    this.hint,
    this.isLoading = false,
    this.emptyMessage = 'Aucun résultat',
  });

  final List<YkDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String label;
  final String? hint;
  final bool isLoading;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const YkSkeleton.line(height: 56);

    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: YkColors.surfaceVariant(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(YkRadius.sm)),
        ),
        child: Text(
          emptyMessage,
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      );
    }

    return DropdownMenu<T>(
      initialSelection: value,
      label: Text(label),
      hintText: hint,
      enableFilter: items.length > 10,
      requestFocusOnTap: true,
      width: double.infinity,
      onSelected: (v) => onChanged(v),
      dropdownMenuEntries: [
        for (final item in items)
          DropdownMenuEntry<T>(
            value: item.value,
            label: item.label,
            leadingIcon: item.icon != null ? Icon(item.icon) : null,
          ),
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YkColors.surfaceVariant(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          borderSide: BorderSide(color: YkColors.border(context)),
        ),
      ),
    );
  }
}
