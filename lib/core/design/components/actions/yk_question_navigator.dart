import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// État d'une question dans [YkQuestionNavigator].
enum YkQuestionEtat {
  /// Une réponse a déjà été saisie.
  repondue,

  /// La question mise en avant (ex. la 1ʳᵉ non répondue) — pas un état
  /// persisté, purement une aide visuelle de navigation.
  enCours,

  /// Pas encore de réponse, pas mise en avant.
  aVenir,
}

/// Rangée de puces numérotées permettant de sauter directement à
/// n'importe quelle question d'un exercice/devoir — maquette « Traiter un
/// devoir / exercice » (`docs/maquette/YEKI App Apprenant.dc.html`,
/// écran Exercices, lignes 1070-1074), absente jusqu'ici des écrans
/// `passer_exercice_page.dart`/`composer_devoir_page.dart` (seule liste
/// défilante linéaire).
class YkQuestionNavigator extends StatelessWidget {
  const YkQuestionNavigator({super.key, required this.etats, required this.onTap});

  /// Un état par question, dans l'ordre d'affichage.
  final List<YkQuestionEtat> etats;

  /// Index de la question tapée.
  final ValueChanged<int> onTap;

  int get _repondues => etats.where((e) => e == YkQuestionEtat.repondue).length;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < etats.length; i++) ...[
                  if (i > 0) SizedBox(width: YkSpacing.xs),
                  _Puce(index: i, etat: etats[i], onTap: () => onTap(i)),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: YkSpacing.sm),
        Text(
          '$_repondues/${etats.length}',
          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context), fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({required this.index, required this.etat, required this.onTap});

  final int index;
  final YkQuestionEtat etat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (etat) {
      case YkQuestionEtat.repondue:
        bg = YkColors.success.withValues(alpha: 0.12);
        fg = YkColors.success;
      case YkQuestionEtat.enCours:
        bg = YkColors.accent(context);
        fg = YkColors.textOnPrimary;
      case YkQuestionEtat.aVenir:
        bg = YkColors.surfaceVariant(context);
        fg = YkColors.textTertiary(context);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(YkRadius.md),
        child: Container(
          width: 34,
          height: 34,
          color: bg,
          alignment: Alignment.center,
          child: Text('${index + 1}', style: YkTypography.caption(context).copyWith(color: fg, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
