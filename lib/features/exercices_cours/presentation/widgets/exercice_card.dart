import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

String _typeLabel(ExerciceListItem ex) {
  if (ex.estEpreuve) return 'Épreuve';
  return switch (ex.typeExercice) {
    'general' => 'Général',
    'module' => 'Module',
    'lecon' => 'Leçon',
    _ => 'Exercice',
  };
}

/// Une carte d'exercice dans la liste de l'onglet « Exercices » — vue
/// combinée apprenant (bouton « Traiter » seul) / enseignant (menu
/// Modifier/Questions/Épreuve/Supprimer en plus).
class ExerciceCard extends StatelessWidget {
  const ExerciceCard({
    super.key,
    required this.exercice,
    required this.courseColor,
    required this.canEdit,
    required this.onTraiter,
    this.onEdit,
    this.onQuestions,
    this.onViewEpreuve,
    this.onDelete,
  });

  final ExerciceListItem exercice;
  final Color courseColor;
  final bool canEdit;
  final VoidCallback onTraiter;
  final VoidCallback? onEdit;
  final VoidCallback? onQuestions;
  final VoidCallback? onViewEpreuve;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        accentColor: courseColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(YkRadius.sm),
                  child: Container(
                    width: 38,
                    height: 38,
                    color: courseColor.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(
                      exercice.estEpreuve ? Icons.assignment_rounded : Icons.assignment_outlined,
                      color: courseColor,
                      size: 22,
                    ),
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercice.titre,
                        style: YkTypography.bodyMd(
                          context,
                        ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      YkRating(value: exercice.etoiles, size: 14),
                      SizedBox(height: 2),
                      YkChip(label: _typeLabel(exercice), variant: YkChipVariant.assist, accentColor: courseColor),
                      if (exercice.moduleNom != null && exercice.typeExercice != 'general')
                        Padding(
                          padding: EdgeInsets.only(top: YkSpacing.xxs),
                          child: Text(
                            exercice.typeExercice == 'lecon' && exercice.leconNom != null
                                ? 'Leçon : ${exercice.leconNom}'
                                : 'Module : ${exercice.moduleNom}',
                            style: YkTypography.bodySm(
                              context,
                            ).copyWith(color: YkColors.textSecondary(context)),
                          ),
                        ),
                    ],
                  ),
                ),
                YkBadge(label: '${exercice.nbQuestions} Q', variant: YkBadgeVariant.label, color: courseColor),
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: YkColors.textSecondary(context)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'questions', child: Text('Questions')),
                      if (exercice.estEpreuve) const PopupMenuItem(value: 'epreuve', child: Text("Voir l'épreuve")),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                    onSelected: (action) => switch (action) {
                      'edit' => onEdit?.call(),
                      'questions' => onQuestions?.call(),
                      'epreuve' => onViewEpreuve?.call(),
                      'delete' => onDelete?.call(),
                      _ => null,
                    },
                  ),
              ],
            ),
            if (exercice.enonce.isNotEmpty) ...[
              SizedBox(height: YkSpacing.sm),
              Text(
                exercice.enonce,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: YkColors.textSecondary(context)),
                SizedBox(width: 4),
                Text(
                  '${exercice.dureeMinutes} min',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                SizedBox(width: YkSpacing.sm),
                Icon(Icons.repeat_rounded, size: 14, color: YkColors.textSecondary(context)),
                SizedBox(width: 4),
                Text(
                  '${exercice.tentativesMax} essai${exercice.tentativesMax > 1 ? "s" : ""}',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                const Spacer(),
                YkButton(
                  label: 'Traiter',
                  icon: Icons.play_arrow_rounded,
                  size: YkButtonSize.sm,
                  onPressed: onTraiter,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
