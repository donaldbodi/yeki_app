import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/guards.dart';
import 'package:yeki/core/theme/app_theme.dart';

/// Cible de la route nommée `/403` — atteinte quand `guards.dart` refuse
/// l'accès à une route pour cause de rôle insuffisant.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

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
              const Icon(Icons.lock_outline_rounded, size: 72, color: YekiColors.error),
              const SizedBox(height: 16),
              const Text(
                'Accès refusé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vous n'avez pas les droits nécessaires pour accéder à cette page.",
                textAlign: TextAlign.center,
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
