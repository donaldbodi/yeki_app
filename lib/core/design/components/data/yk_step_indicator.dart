import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

enum _YkStepState { done, active, upcoming }

/// Indicateur d'étapes — CDC_DESIGN (maquette : composant « GlassStepper »,
/// jamais porté en Flutter avant P5.4, voir docs/ecarts/register.md).
/// Cercles terminé (✓)/actif/à venir reliés par une ligne de progression.
/// Nombre d'étapes variable (pas figé à 3 comme la maquette) — purement
/// présentation, ne gère aucune navigation.
class YkStepIndicator extends StatelessWidget {
  const YkStepIndicator({super.key, required this.labels, required this.currentIndex})
      : assert(labels.length >= 2, 'YkStepIndicator exige au moins 2 étapes.'),
        assert(
          currentIndex >= 0,
          'currentIndex doit être compris entre 0 et labels.length - 1.',
        );

  /// Libellé de chaque étape, dans l'ordre.
  final List<String> labels;

  /// Index (0-based) de l'étape active. Les index inférieurs sont
  /// considérés terminés (✓), les index supérieurs à venir.
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${currentIndex + 1} sur ${labels.length} : ${labels[currentIndex]}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= currentIndex ? YkColors.success : YkColors.border(context),
                    ),
                  ),
                _StepCircle(state: _stateFor(i), stepNumber: i + 1),
              ],
            ],
          ),
          SizedBox(height: YkSpacing.xxs),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: YkTypography.label(context).copyWith(
                      color: i == currentIndex
                          ? YkColors.accent(context)
                          : YkColors.textSecondary(context),
                      fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _YkStepState _stateFor(int index) {
    if (index < currentIndex) return _YkStepState.done;
    if (index == currentIndex) return _YkStepState.active;
    return _YkStepState.upcoming;
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.state, required this.stepNumber});

  final _YkStepState state;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _YkStepState.done:
        return CircleAvatar(
          radius: 16,
          backgroundColor: YkColors.success,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        );
      case _YkStepState.active:
        return CircleAvatar(
          radius: 18,
          backgroundColor: YkColors.accent(context).withValues(alpha: 0.16),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: YkColors.accent(context),
            child: Text(
              '$stepNumber',
              style: YkTypography.label(context).copyWith(color: YkColors.onAccent(context)),
            ),
          ),
        );
      case _YkStepState.upcoming:
        return CircleAvatar(
          radius: 16,
          backgroundColor: YkColors.surfaceVariant(context),
          child: Text(
            '$stepNumber',
            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
          ),
        );
    }
  }
}
