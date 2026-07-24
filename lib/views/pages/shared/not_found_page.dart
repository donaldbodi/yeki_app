import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/guards.dart';
import 'package:yeki/core/theme/app_theme.dart';

/// Cible de `GoRouter.errorBuilder` (chemin non reconnu) et de la route
/// nommée `/404`. Écran volontairement simple — ce ticket porte sur le
/// routage, pas sur un travail visuel.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 72, color: YekiColors.textMedium),
              const SizedBox(height: 16),
              const Text(
                'Page introuvable',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Cette page n'existe pas ou plus.",
                style: TextStyle(color: YekiColors.textMedium),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(homePathForRole(authState.value.role)),
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
