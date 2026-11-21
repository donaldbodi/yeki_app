import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Notation par étoiles — CDC_DESIGN §5.3.4 : lecture seule ou saisie.
/// Généralise le champ `etoiles` (difficulté d'exercice, 1-3 dans le
/// modèle actuel, jusqu'à 5 ici).
class YkRating extends StatelessWidget {
  const YkRating({super.key, required this.value, this.max = 5, this.onChanged, this.size = 20});

  final int value;
  final int max;

  /// `null` = lecture seule.
  final ValueChanged<int>? onChanged;
  final double size;

  bool get _readOnly => onChanged == null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value étoiles sur $max',
      slider: !_readOnly,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= max; i++)
            _readOnly
                ? Icon(
                    i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size,
                    color: YkColors.warning,
                  )
                : InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onChanged!(i),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: size,
                        color: YkColors.warning,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}
