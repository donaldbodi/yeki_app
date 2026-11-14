import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/guards.dart';

/// Cible de `GoRouter.errorBuilder` (chemin non reconnu) et de la route
/// nommée `/404`. Écran volontairement simple — ce ticket porte sur le
/// routage, pas sur un travail visuel.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

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
              Icon(Icons.search_off_rounded, size: 72, color: YkColors.textSecondary(context)),
              SizedBox(height: YkSpacing.md),
              Text(
                'Page introuvable',
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              SizedBox(height: YkSpacing.xs),
              Text(
                "Cette page n'existe pas ou plus.",
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
