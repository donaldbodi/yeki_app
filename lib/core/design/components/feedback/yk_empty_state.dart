import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// État vide — CDC_DESIGN §5.3.6.
///
/// `title` et `message` sont volontairement **requis, sans texte
/// générique par défaut** : « Aucun devoir publié pour l'instant » ≠
/// « Aucun résultat pour ce filtre » ≠ « Vous n'avez pas encore d'accès à
/// ce cours ». Trois messages différents, jamais un générique — cette
/// contrainte est imposée par l'API du composant, pas laissée à
/// l'appréciation de l'intégrateur.
class YkEmptyState extends StatelessWidget {
  const YkEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(YkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: YkColors.textTertiary(context)),
            SizedBox(height: YkSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: YkSpacing.lg),
              YkButton(label: actionLabel!, onPressed: onAction, variant: YkButtonVariant.secondary),
            ],
          ],
        ),
      ),
    );
  }
}
