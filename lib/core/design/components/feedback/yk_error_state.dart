import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// État d'erreur — CDC_DESIGN §5.3.6.
///
/// `message` doit être un texte compréhensible par l'apprenant. **Ne
/// jamais y passer un code d'erreur brut** (ex. `"Exception: 500"`,
/// `"DioError [ResponseType.json]..."`) — c'est la responsabilité de
/// l'appelant de traduire l'erreur technique en phrase lisible avant de
/// la transmettre à ce composant.
class YkErrorState extends StatelessWidget {
  const YkErrorState({
    super.key,
    required this.message,
    this.cause,
    this.onRetry,
    this.onContactSupport,
    this.icon = Icons.error_outline,
  });

  final IconData icon;
  final String message;

  /// Cause probable, optionnelle (ex. « Vérifiez votre connexion »).
  final String? cause;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(YkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: YkColors.error),
            SizedBox(height: YkSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            if (cause != null) ...[
              SizedBox(height: YkSpacing.xs),
              Text(
                cause!,
                textAlign: TextAlign.center,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: YkSpacing.lg),
              YkButton(
                label: 'Réessayer',
                icon: Icons.refresh,
                onPressed: onRetry,
                variant: YkButtonVariant.primary,
              ),
            ],
            if (onContactSupport != null) ...[
              SizedBox(height: YkSpacing.sm),
              YkButton(
                label: 'Contacter le support',
                onPressed: onContactSupport,
                variant: YkButtonVariant.ghost,
                size: YkButtonSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
