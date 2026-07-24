import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// Un plan tarifaire — texte/prix/CTA tous fournis par l'appelant.
class YkPaywallPlan {
  const YkPaywallPlan({required this.label, required this.priceLabel, this.badge, required this.onSelect});

  final String label;

  /// Texte déjà formaté (ex. « 1 500 FCFA/mois ») — **jamais un chiffre
  /// figé dans le composant** (règle 3 : c'est une valeur métier).
  final String priceLabel;
  final String? badge;
  final VoidCallback onSelect;
}

/// Écran de conversion premium — CDC_DESIGN §5.3.7/§7.4.
///
/// `cours_detail_page.dart` a déjà un `_buildPremiumLock` abouti, mais
/// avec les prix **en dur dans l'écran** (13000F/1500F) — violation
/// règle 3 déjà présente dans le code actuel, signalée, non corrigée ici
/// (écran non touché). Ce composant est conçu générique pour que le jour
/// où cet écran est migré, aucun prix ne soit plus jamais figé dans le
/// widget lui-même.
class YkPaywall extends StatelessWidget {
  const YkPaywall({
    super.key,
    required this.title,
    required this.description,
    required this.features,
    required this.plans,
  });

  final String title;
  final String description;
  final List<String> features;
  final List<YkPaywallPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.lg),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        borderRadius: BorderRadius.circular(YkRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.workspace_premium, size: 40, color: YkColors.warning),
          SizedBox(height: YkSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          for (final feature in features)
            Padding(
              padding: EdgeInsets.symmetric(vertical: YkSpacing.xxs),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: YkColors.success, size: 18),
                  SizedBox(width: YkSpacing.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: YkSpacing.md),
          for (var i = 0; i < plans.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.sm),
              child: YkButton(
                label: '${plans[i].label} — ${plans[i].priceLabel}',
                onPressed: plans[i].onSelect,
                variant: i == 0 ? YkButtonVariant.primary : YkButtonVariant.secondary,
              ),
            ),
        ],
      ),
    );
  }
}
