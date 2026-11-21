import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

String _statutLabel(DevoirListItem d) {
  if (!d.estPublie) return 'Brouillon';
  if (d.estExpire) return 'Expiré';
  if (d.estOuvert) return 'Ouvert';
  return 'Publié';
}

Color _statutColor(BuildContext context, DevoirListItem d) {
  if (!d.estPublie) return YkColors.textTertiary(context);
  if (d.estExpire) return YkColors.error;
  if (d.estOuvert) return YkColors.success;
  return YkColors.info;
}

/// Une carte devoir — vue combinée apprenant (action Démarrer/Continuer/
/// Voir résultat) / enseignant (action Gérer + menu Dupliquer/Publier).
class DevoirCard extends StatelessWidget {
  const DevoirCard({
    super.key,
    required this.devoir,
    required this.courseColor,
    required this.canEdit,
    required this.onGerer,
    this.onDemarrer,
    this.onDupliquer,
    this.onPublier,
  });

  final DevoirListItem devoir;
  final Color courseColor;
  final bool canEdit;

  /// Enseignant : ouvre l'écran de composition.
  final VoidCallback onGerer;

  /// Apprenant : démarrer/continuer/voir résultat (déjà géré par
  /// l'écran appelant selon `devoir.maSoumission`).
  final VoidCallback? onDemarrer;
  final VoidCallback? onDupliquer;
  final Future<void> Function()? onPublier;

  @override
  Widget build(BuildContext context) {
    final statutColor = _statutColor(context, devoir);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        variant: YkCardVariant.tinted,
        accentColor: courseColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(YkRadius.md),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: courseColor.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(Icons.assignment_outlined, color: courseColor, size: 24),
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devoir.titre,
                        style: YkTypography.bodyMd(
                          context,
                        ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      YkChip(label: _statutLabel(devoir), variant: YkChipVariant.assist, accentColor: statutColor),
                    ],
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: YkColors.textSecondary(context)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'gerer', child: Text('Gérer')),
                      const PopupMenuItem(value: 'dupliquer', child: Text('Dupliquer')),
                      if (!devoir.estPublie) const PopupMenuItem(value: 'publier', child: Text('Publier')),
                    ],
                    onSelected: (action) => switch (action) {
                      'gerer' => onGerer(),
                      'dupliquer' => onDupliquer?.call(),
                      'publier' => onPublier?.call(),
                      _ => null,
                    },
                  ),
              ],
            ),
            if (devoir.description.isNotEmpty) ...[
              SizedBox(height: YkSpacing.sm),
              Text(
                devoir.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            Wrap(
              spacing: YkSpacing.sm,
              runSpacing: YkSpacing.xxs,
              children: [
                _info(context, Icons.stars_outlined, '${devoir.noteSur.toStringAsFixed(0)} pt'),
                _info(context, Icons.timer_outlined, '${devoir.dureeMinutes} min'),
                if (devoir.dateLimite != null)
                  _info(
                    context,
                    Icons.event_outlined,
                    'Échéance : ${DateFormat('dd/MM/yyyy').format(devoir.dateLimite!)}',
                  ),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                if (canEdit && devoir.stats != null) ...[
                  Icon(Icons.people_outline, size: 14, color: YkColors.textSecondary(context)),
                  SizedBox(width: 4),
                  Text(
                    '${devoir.stats!.nbCorriges}/${devoir.stats!.nbSoumissions} copies corrigées',
                    style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                ] else if (!canEdit && devoir.maSoumission != null) ...[
                  Icon(Icons.info_outline, size: 14, color: YkColors.textSecondary(context)),
                  SizedBox(width: 4),
                  Text(
                    devoir.maSoumission!.note != null
                        ? 'Note : ${devoir.maSoumission!.note!.toStringAsFixed(1)}/${devoir.noteSur.toStringAsFixed(0)}'
                        : 'Statut : ${devoir.maSoumission!.statut}',
                    style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                ],
                const Spacer(),
                if (canEdit)
                  YkButton(
                    label: 'Gérer',
                    icon: Icons.edit_note_rounded,
                    size: YkButtonSize.sm,
                    color: courseColor,
                    onPressed: onGerer,
                  )
                else if (onDemarrer != null)
                  YkButton(
                    label: devoir.maSoumission == null ? 'Démarrer' : 'Continuer',
                    icon: Icons.play_arrow_rounded,
                    size: YkButtonSize.sm,
                    color: courseColor,
                    onPressed: onDemarrer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: YkColors.textSecondary(context)),
        SizedBox(width: 4),
        Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
      ],
    );
  }
}
