import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// Politique de sortie — CDC_DESIGN §5.6. **Deux règles différentes, à ne
/// jamais confondre** (cause probable des incohérences historiques de la
/// logique devoir) :
///
/// - Exercice, tentatives restantes → sortie = soumission automatique
///   (tentative comptée).
/// - Exercice, tentatives épuisées → sortie libre, **aucun avertissement**.
/// - Devoir, tentatives restantes → sortie = tentative comptée, **pas** de
///   soumission (un devoir se rend une seule fois).
/// - Devoir, tentatives épuisées → sortie = soumission automatique (rendu).
///
/// [YkConfirmSheet] reçoit cette politique, jamais un texte libre — c'est
/// ce qui rend l'écart impossible à réintroduire par erreur.
enum YkExitPolicy { exerciceTentativesRestantes, exerciceTentativesEpuisees, devoirTentativesRestantes, devoirTentativesEpuisees }

class _YkConfirmContent {
  const _YkConfirmContent({required this.title, required this.message, required this.confirmLabel});

  final String title;
  final String message;
  final String confirmLabel;
}

/// Confirmation de sortie de page — CDC_DESIGN §5.3.6/§5.6.
///
/// Ne fait **aucun appel réseau** : retourne uniquement la décision de
/// l'apprenant (quitter/rester). Quel appel déclencher en conséquence
/// (`sortir`, `evaluer`, `soumettre`, ou rien) reste la responsabilité de
/// l'écran appelant.
class YkConfirmSheet {
  YkConfirmSheet._();

  /// Retourne `true` s'il faut quitter (pop), `false` sinon.
  ///
  /// [YkExitPolicy.exerciceTentativesEpuisees] retourne `true`
  /// immédiatement, **sans afficher de sheet** — règle explicite : sortie
  /// libre, jamais d'avertissement quand les tentatives d'exercice sont
  /// épuisées.
  static Future<bool> confirmExit(BuildContext context, {required YkExitPolicy policy}) async {
    if (policy == YkExitPolicy.exerciceTentativesEpuisees) return true;

    final content = _contentFor(policy);
    final decision = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _YkConfirmSheetView(content: content),
    );
    return decision ?? false;
  }

  static _YkConfirmContent _contentFor(YkExitPolicy policy) {
    switch (policy) {
      case YkExitPolicy.exerciceTentativesRestantes:
        // Message EXACT imposé par le ticket P6.4 — l'écrit prime sur
        // toute formulation antérieure (règle 4).
        return const _YkConfirmContent(
          title: "Quitter l'exercice ?",
          message:
              'Si vous quittez maintenant, votre tentative sera soumise '
              'automatiquement avec les réponses déjà fournies. Cette '
              'tentative sera comptée dans votre nombre de tentatives '
              'autorisées. Souhaitez-vous continuer ?',
          confirmLabel: 'Quitter et soumettre',
        );
      case YkExitPolicy.devoirTentativesRestantes:
        return const _YkConfirmContent(
          title: 'Quitter le devoir ?',
          message:
              'Si vous quittez maintenant, la tentative sera comptée. '
              'Votre devoir ne sera pas soumis.',
          confirmLabel: 'Quitter (tentative comptée)',
        );
      case YkExitPolicy.devoirTentativesEpuisees:
        return const _YkConfirmContent(
          title: 'Tentatives épuisées',
          message:
              'Vos tentatives sont épuisées. Si vous quittez maintenant, '
              "votre devoir sera soumis automatiquement en l'état et "
              'considéré comme rendu.',
          confirmLabel: 'Quitter et soumettre',
        );
      case YkExitPolicy.exerciceTentativesEpuisees:
        // Sortie libre, interceptée avant d'atteindre ce point —
        // voir confirmExit.
        throw StateError('exerciceTentativesEpuisees ne doit jamais afficher de sheet.');
    }
  }
}

class _YkConfirmSheetView extends StatelessWidget {
  const _YkConfirmSheetView({required this.content});

  final _YkConfirmContent content;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(YkSpacing.sm),
        padding: EdgeInsets.all(YkSpacing.lg),
        decoration: BoxDecoration(
          color: YkColors.surface(context),
          borderRadius: BorderRadius.circular(YkRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: YkColors.border(context),
                  borderRadius: BorderRadius.circular(YkRadius.full),
                ),
              ),
            ),
            SizedBox(height: YkSpacing.md),
            Text(
              content.title,
              style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              content.message,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(
              label: content.confirmLabel,
              variant: YkButtonVariant.destructive,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            SizedBox(height: YkSpacing.sm),
            YkButton(
              label: 'Rester',
              variant: YkButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
