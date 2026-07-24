import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_chip.dart';

class YkMultiSelectItem<T> {
  const YkMultiSelectItem({required this.value, required this.label});
  final T value;
  final String label;
}

/// Sélection multiple avec puces — CDC_DESIGN §5.3.2 (niveaux
/// accessibles d'une olympiade, exercices composant une épreuve).
class YkMultiSelect<T> extends StatelessWidget {
  const YkMultiSelect({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.label,
  });

  final List<YkMultiSelectItem<T>> items;
  final Set<T> selectedValues;
  final ValueChanged<Set<T>> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
        ],
        Wrap(
          spacing: YkSpacing.xs,
          runSpacing: YkSpacing.xs,
          children: [
            for (final item in items)
              YkChip(
                label: item.label,
                variant: YkChipVariant.filter,
                selected: selectedValues.contains(item.value),
                onSelected: (sel) {
                  final next = Set<T>.from(selectedValues);
                  if (sel) {
                    next.add(item.value);
                  } else {
                    next.remove(item.value);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
