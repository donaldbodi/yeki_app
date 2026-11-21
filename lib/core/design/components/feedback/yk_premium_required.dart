import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// État « abonnement Premium requis » — distinct du verrou d'accès
/// département (`isPremium`/`estAccessible`, `CoursDetailTabs.
/// _buildPremiumLock`) : ce composant couvre le blocage RÉEL du backend
/// (`AccesMatricePermission`, `apps/core/permissions.py`) sur les
/// apprenants sans `AbonnementPremium` actif — indépendant de l'accès au
/// département/cours, deux gates économiques séparés côté backend.
class YkPremiumRequired extends StatelessWidget {
  const YkPremiumRequired({super.key, required this.message, this.onSubscribe});

  /// Message backend (`AccesMatricePermission.message`), déjà lisible.
  final String message;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(YkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: YkColors.warning, size: 56),
            SizedBox(height: YkSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            if (onSubscribe != null) ...[
              SizedBox(height: YkSpacing.lg),
              YkButton(label: "S'abonner", icon: Icons.workspace_premium_rounded, onPressed: onSubscribe),
            ],
          ],
        ),
      ),
    );
  }
}
