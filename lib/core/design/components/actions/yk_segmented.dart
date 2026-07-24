import 'package:flutter/material.dart';

/// Un segment de [YkSegmented].
class YkSegment<T> {
  const YkSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Bascule à 2-5 segments — CDC_DESIGN §5.3.1. Remplace les rangées de
/// boutons faites main dans les filtres (ex. exercices/devoirs par
/// difficulté ou par tri).
class YkSegmented<T> extends StatelessWidget {
  const YkSegmented({super.key, required this.segments, required this.selected, required this.onChanged})
    : assert(
        segments.length >= 2 && segments.length <= 5,
        'YkSegmented accepte de 2 à 5 segments (CDC_DESIGN §5.3.1).',
      );

  final List<YkSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [
        for (final s in segments)
          ButtonSegment<T>(value: s.value, label: Text(s.label), icon: s.icon != null ? Icon(s.icon) : null),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
      showSelectedIcon: false,
    );
  }
}
