import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

/// Un énoncé et SES questions (P7.1 : « un énoncé a plusieurs
/// questions, CES questions ») — un panneau dépliable par énoncé, la
/// hiérarchie « un énoncé → ses questions → un autre énoncé → ses
/// questions » demandée par le ticket P7.4.
class EnonceSection extends StatelessWidget {
  const EnonceSection({
    super.key,
    required this.enonce,
    required this.index,
    required this.canEdit,
    required this.peutModifier,
    required this.onEditerEnonce,
    this.onSupprimerEnonce,
    required this.onAjouterQuestion,
    required this.onEditerQuestion,
    required this.onSupprimerQuestion,
  });

  final EnonceDevoirItem enonce;
  final int index;
  final bool canEdit;

  /// `false` si le devoir est publié — questions/énoncés en lecture
  /// seule (P7.1/P7.2), désactivé + expliqué plutôt qu'un bouton mort.
  final bool peutModifier;

  final VoidCallback onEditerEnonce;
  final VoidCallback? onSupprimerEnonce;
  final VoidCallback onAjouterQuestion;
  final ValueChanged<QuestionDevoirItem> onEditerQuestion;
  final ValueChanged<QuestionDevoirItem> onSupprimerQuestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        padding: EdgeInsets.zero,
        child: YkExpansion(
          title: 'Énoncé $index',
          subtitle: '${enonce.questions.length} question${enonce.questions.length > 1 ? "s" : ""}',
          initiallyExpanded: index == 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YkRichViewer(html: enonce.contenu),
              SizedBox(height: YkSpacing.sm),
              if (canEdit) ...[
                if (!peutModifier)
                  Padding(
                    padding: EdgeInsets.only(bottom: YkSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: YkColors.textSecondary(context)),
                        SizedBox(width: YkSpacing.xxs),
                        Expanded(
                          child: Text(
                            'Devoir publié : énoncés et questions en lecture seule.',
                            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    YkButton(
                      label: 'Modifier l\'énoncé',
                      variant: YkButtonVariant.ghost,
                      size: YkButtonSize.sm,
                      onPressed: peutModifier ? onEditerEnonce : null,
                    ),
                    if (onSupprimerEnonce != null) ...[
                      SizedBox(width: YkSpacing.xs),
                      YkButton(
                        label: 'Supprimer',
                        variant: YkButtonVariant.ghost,
                        size: YkButtonSize.sm,
                        onPressed: peutModifier ? onSupprimerEnonce : null,
                      ),
                    ],
                  ],
                ),
              ],
              const Divider(),
              for (final question in enonce.questions) _buildQuestion(context, question),
              if (canEdit)
                Padding(
                  padding: EdgeInsets.only(top: YkSpacing.xs),
                  child: YkButton(
                    label: 'Ajouter une question',
                    icon: Icons.add,
                    variant: YkButtonVariant.secondary,
                    size: YkButtonSize.sm,
                    onPressed: peutModifier ? onAjouterQuestion : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, QuestionDevoirItem question) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              YkChip(label: question.estQcm ? 'QCM' : 'Texte libre', variant: YkChipVariant.assist),
              SizedBox(width: YkSpacing.xs),
              Text(
                '${question.points.toStringAsFixed(question.points.truncateToDouble() == question.points ? 0 : 2)} pt',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              const Spacer(),
              if (canEdit)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    YkIconButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier la question',
                      variant: YkIconButtonVariant.ghost,
                      onPressed: peutModifier ? () => onEditerQuestion(question) : null,
                    ),
                    YkIconButton(
                      icon: Icons.delete_outline,
                      label: 'Supprimer la question',
                      variant: YkIconButtonVariant.ghost,
                      onPressed: peutModifier ? () => onSupprimerQuestion(question) : null,
                    ),
                  ],
                ),
            ],
          ),
          YkRichViewer(html: question.enonce),
          if (question.estQcm)
            ...question.choix.map(
              (c) => Padding(
                padding: EdgeInsets.only(top: YkSpacing.xxs),
                child: Row(
                  children: [
                    Icon(
                      c.estCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: c.estCorrect ? YkColors.success : YkColors.textTertiary(context),
                    ),
                    SizedBox(width: YkSpacing.xs),
                    Text(
                      c.texte,
                      style: YkTypography.bodySm(context).copyWith(
                        color: c.estCorrect ? YkColors.success : YkColors.textPrimary(context),
                        fontWeight: c.estCorrect ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (question.reponseAttendue.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: YkSpacing.xxs),
              child: Text(
                'Réponse attendue : ${question.reponseAttendue}',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.success, fontWeight: FontWeight.w700),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
