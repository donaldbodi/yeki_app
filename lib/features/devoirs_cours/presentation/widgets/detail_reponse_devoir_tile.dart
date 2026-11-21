import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

/// Affiche `1` plutôt que `1.00`, mais garde les décimales utiles.
String _formatPoints(double points) {
  final entier = points.truncateToDouble() == points;
  return entier ? points.toStringAsFixed(0) : points.toStringAsFixed(2);
}

/// Rendu de la correction d'UNE question de devoir —
/// `SoumissionResultatSerializer.get_questions_detail` (P7.3/P7.6).
/// Contrairement à `DetailReponseTile` (exercice, P6.4/P6.5), le devoir
/// expose le snapshot COMPLET des choix QCM (`choix[].estCorrect`) : les
/// deux widgets ne sont donc PAS fusionnables malgré la ressemblance —
/// des modèles de données différents (`DetailReponse` vs
/// `DetailReponseDevoir`).
class DetailReponseDevoirTile extends StatelessWidget {
  const DetailReponseDevoirTile({super.key, required this.detail, required this.index});

  final DetailReponseDevoir detail;
  final int index;

  @override
  Widget build(BuildContext context) {
    // `estCorrect == null` : question texte libre d'un devoir en
    // correction MANUELLE, pas encore corrigée par l'enseignant — état
    // neutre, ni réussi ni échoué (à ne jamais confondre avec `false`).
    final enAttente = detail.estCorrect == null;
    final color = enAttente
        ? YkColors.textSecondary(context)
        : (detail.estCorrect! ? YkColors.success : YkColors.error);

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        variant: YkCardVariant.outlined,
        accentColor: color.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  enAttente
                      ? Icons.hourglass_top_rounded
                      : (detail.estCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded),
                  color: color,
                  size: 18,
                ),
                SizedBox(width: YkSpacing.xs),
                Text(
                  'Question $index',
                  style: YkTypography.label(context).copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (!enAttente)
                  YkChip(
                    label: '${_formatPoints(detail.pointsObtenus ?? 0)} / ${_formatPoints(detail.pointsMax)} pts',
                    variant: YkChipVariant.assist,
                    accentColor: color,
                  ),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            YkRichViewer(html: detail.questionEnonce),
            SizedBox(height: YkSpacing.sm),
            if (detail.estQcm) ..._buildChoixQcm(context) else ..._buildReponseTexte(context, color, enAttente),
          ],
        ),
      ),
    );
  }

  /// QCM : TOUTES les options (pas seulement celle sélectionnée) — c'est
  /// précisément l'absence de ce rendu qui causait le bug historique
  /// « l'apprenant ne voit pas la bonne réponse » (corrigé côté backend
  /// en P7.3, ce widget en est la première consommation réelle).
  List<Widget> _buildChoixQcm(BuildContext context) {
    return [
      for (final c in detail.choix)
        Padding(
          padding: EdgeInsets.only(bottom: YkSpacing.xs),
          child: _ligneChoix(context, c),
        ),
    ];
  }

  Widget _ligneChoix(BuildContext context, ChoixResultatDevoir c) {
    final estSelectionne = c.texte == detail.choixSelectionne;
    final Color color;
    final IconData icon;
    if (c.estCorrect) {
      color = YkColors.success;
      icon = Icons.check_circle_rounded;
    } else if (estSelectionne) {
      color = YkColors.error;
      icon = Icons.cancel_rounded;
    } else {
      color = YkColors.textTertiary(context);
      icon = Icons.circle_outlined;
    }

    return YkCard(
      variant: (c.estCorrect || estSelectionne) ? YkCardVariant.filled : YkCardVariant.outlined,
      accentColor: (c.estCorrect || estSelectionne) ? color : null,
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Text(
              c.texte,
              style: YkTypography.bodyMd(
                context,
              ).copyWith(color: YkColors.textPrimary(context), fontWeight: estSelectionne ? FontWeight.w700 : null),
            ),
          ),
        ],
      ),
    );
  }

  /// Texte libre : la réponse rédigée, la réponse attendue si erronée, et
  /// l'exemple de réponse de l'enseignant si fourni.
  List<Widget> _buildReponseTexte(BuildContext context, Color color, bool enAttente) {
    return [
      if (detail.reponseUtilisateur.isNotEmpty) _ligne(context, 'Votre réponse', detail.reponseUtilisateur, color),
      if (!enAttente && detail.estCorrect == false && (detail.bonneReponse ?? '').isNotEmpty) ...[
        SizedBox(height: YkSpacing.xxs),
        _ligne(context, 'Réponse attendue', detail.bonneReponse!, YkColors.success),
      ],
      if (detail.reponseExemple.isNotEmpty) ...[
        SizedBox(height: YkSpacing.sm),
        Container(
          padding: EdgeInsets.all(YkSpacing.sm),
          decoration: BoxDecoration(
            color: YkColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(YkRadius.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: YkColors.info),
              SizedBox(width: YkSpacing.xs),
              Expanded(
                child: Text(
                  'Exemple : ${detail.reponseExemple}',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _ligne(BuildContext context, String label, String valeur, Color color) {
    return RichText(
      text: TextSpan(
        style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(text: valeur, style: YkTypography.bodySm(context).copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
