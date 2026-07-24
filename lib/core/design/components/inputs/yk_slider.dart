import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Curseur de valeur — CDC_DESIGN §5.3.2.
///
/// [step] est **requis, sans valeur par défaut** (règle 3 : le pas d'un
/// barème de points, par ex. 0,25, est une valeur métier — jamais figée
/// dans le composant, toujours fournie par l'écran appelant).
class YkSlider extends StatelessWidget {
  const YkSlider({
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

  @override
  Widget build(BuildContext context) {
    final divisionsRaw = step > 0 ? ((max - min) / step).round() : 0;
    final displayValue = valueFormatter?.call(value) ?? value.toStringAsFixed(step < 1 ? 2 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              Text(
                displayValue,
                style: YkTypography.label(context).copyWith(color: YkColors.accent(context)),
              ),
            ],
          ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisionsRaw > 0 ? divisionsRaw : null,
          label: displayValue,
          activeColor: YkColors.accent(context),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
