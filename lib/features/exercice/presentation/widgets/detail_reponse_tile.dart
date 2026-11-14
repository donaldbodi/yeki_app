import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

/// Rendu d'une correction de question — consomme `DetailReponse` (déjà
/// unifié en P6.4 : `fromSoumission`/`fromHistorique` normalisent les
/// deux formes de clés renvoyées par le backend). Remplace les TROIS
/// implémentations dupliquées de l'ancien `resultat_exercice_page.dart`
/// (`_buildDetailQuestion`, l'historique inline, la sheet modale) —
/// règle 1, une seule source de rendu pour ce concept.
class DetailReponseTile extends StatelessWidget {
  const DetailReponseTile({super.key, required this.detail, required this.index});

  final DetailReponse detail;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = detail.estCorrect ? YkColors.success : YkColors.error;

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
                  detail.estCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color,
                  size: 18,
                ),
                SizedBox(width: YkSpacing.xs),
                Text(
                  'Question $index',
                  style: YkTypography.label(context).copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                YkChip(
                  label:
                      '${detail.pointsObtenus.toStringAsFixed(detail.pointsObtenus.truncateToDouble() == detail.pointsObtenus ? 0 : 2)}'
                      ' / ${detail.pointsMax.toStringAsFixed(detail.pointsMax.truncateToDouble() == detail.pointsMax ? 0 : 2)} pts',
                  variant: YkChipVariant.assist,
                  accentColor: color,
                ),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              detail.enonce,
              style: YkTypography.bodyMd(context).copyWith(
                color: YkColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail.reponseApprenant.isNotEmpty) ...[
              SizedBox(height: YkSpacing.sm),
              _ligne(context, 'Votre réponse', detail.reponseApprenant, color),
            ],
            if (!detail.estCorrect && detail.bonneReponse.isNotEmpty) ...[
              SizedBox(height: YkSpacing.xxs),
              _ligne(context, 'Bonne réponse', detail.bonneReponse, YkColors.success),
            ],
            if (detail.explication.isNotEmpty) ...[
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
                        detail.explication,
                        style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, String label, String valeur, Color color) {
    return RichText(
      text: TextSpan(
        style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(
            text: valeur,
            style: YkTypography.bodySm(context).copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
