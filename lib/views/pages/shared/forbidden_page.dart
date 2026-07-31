import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/guards.dart';

/// Cible de la route nommée `/403` — atteinte quand `guards.dart` refuse
/// l'accès à une route pour cause de rôle insuffisant.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(YkSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 72, color: YkColors.error),
              SizedBox(height: YkSpacing.md),
              Text(
                'Accès refusé',
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              SizedBox(height: YkSpacing.xs),
              Text(
                "Vous n'avez pas les droits nécessaires pour accéder à cette page.",
                textAlign: TextAlign.center,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              SizedBox(height: YkSpacing.lg),
              YkButton(
                label: "Retour à l'accueil",
                onPressed: () => context.go(homePathForRole(authState.value.role)),
                variant: YkButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
