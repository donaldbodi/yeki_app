import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

/// Incrément numérique — CDC_DESIGN §5.3.2.
///
/// [step] est **requis** (règle 3 : 0,25 pour les points, 1 pour les
/// tentatives/durées — jamais figé dans le composant).
class YkStepper extends StatelessWidget {
  const YkStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.label,
    this.valueFormatter,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? label;
  final String Function(double)? valueFormatter;

  void _decrement() {
    final next = (value - step).clamp(min, max);
    if (next != value) onChanged(next);
  }

  void _increment() {
    final next = (value + step).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final display = valueFormatter?.call(value) ?? value.toStringAsFixed(step < 1 ? 2 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(width: YkSpacing.sm),
        ],
        YkIconButton(
          icon: Icons.remove,
          label: 'Diminuer',
          variant: YkIconButtonVariant.outlined,
          onPressed: value > min ? _decrement : null,
        ),
        SizedBox(width: YkSpacing.sm),
        SizedBox(
          width: 48,
          child: Text(
            display,
            textAlign: TextAlign.center,
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
          ),
        ),
        SizedBox(width: YkSpacing.sm),
        YkIconButton(
          icon: Icons.add,
          label: 'Augmenter',
          variant: YkIconButtonVariant.outlined,
          onPressed: value < max ? _increment : null,
        ),
      ],
    );
  }
}
