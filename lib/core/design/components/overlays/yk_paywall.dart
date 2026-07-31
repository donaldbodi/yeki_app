import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../containers/yk_card.dart';

/// Un plan tarifaire — texte/prix/CTA tous fournis par l'appelant.
class YkPaywallPlan {
  const YkPaywallPlan({
    required this.label,
    required this.priceLabel,
    this.badge,
    this.ancienPrixLabel,
    this.economieLabel,
    required this.onSelect,
  });

  final String label;

  /// Texte déjà formaté (ex. « 1 500 FCFA/mois ») — **jamais un chiffre
  /// figé dans le composant** (règle 3 : c'est une valeur métier).
  final String priceLabel;
  final String? badge;

  /// Ancien prix, barré, affiché à côté de [priceLabel] — ex. « Promotion »
  /// avec un historique de baisse. `null` si aucune promotion en cours.
  final String? ancienPrixLabel;

  /// Économie réalisée déjà formatée (ex. « Économisez 8 000 FCFA vs
  /// mensuel ») — typiquement sur l'offre annuelle. `null` sinon.
  final String? economieLabel;
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
    this.presentielLabel,
    this.presentielDescription,
    this.onSelectPresentiel,
  });

  final String title;
  final String description;
  final List<String> features;
  final List<YkPaywallPlan> plans;

  /// Le présentiel est un COMPLÉMENT optionnel, jamais un prérequis —
  /// rendu dans une carte séparée, en retrait des [plans] principaux
  /// (exigence explicite P9.3 : ne jamais le présenter comme obligatoire).
  final String? presentielLabel;
  final String? presentielDescription;
  final VoidCallback? onSelectPresentiel;

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
            Padding(padding: EdgeInsets.only(bottom: YkSpacing.sm), child: _buildPlan(context, plans[i], i == 0)),
          if (presentielLabel != null) ...[SizedBox(height: YkSpacing.xs), _buildPresentiel(context)],
        ],
      ),
    );
  }

  Widget _buildPlan(BuildContext context, YkPaywallPlan plan, bool misEnAvant) {
    return YkCard(
      variant: misEnAvant ? YkCardVariant.filled : YkCardVariant.outlined,
      accentColor: misEnAvant ? YkColors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.label,
                  style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                ),
              ),
              if (plan.badge != null) _buildBadge(context, plan.badge!),
            ],
          ),
          SizedBox(height: YkSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (plan.ancienPrixLabel != null) ...[
                Text(
                  plan.ancienPrixLabel!,
                  style: YkTypography.bodySm(context).copyWith(
                    color: YkColors.textTertiary(context),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: YkSpacing.xs),
              ],
              Text(
                plan.priceLabel,
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ],
          ),
          if (plan.economieLabel != null) ...[
            SizedBox(height: YkSpacing.xxs),
            Text(
              plan.economieLabel!,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.success, fontWeight: FontWeight.w600),
            ),
          ],
          SizedBox(height: YkSpacing.sm),
          YkButton(
            label: 'Choisir',
            onPressed: plan.onSelect,
            variant: misEnAvant ? YkButtonVariant.primary : YkButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String badge) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs, vertical: YkSpacing.xxs),
      decoration: BoxDecoration(color: YkColors.warning, borderRadius: BorderRadius.circular(YkRadius.sm)),
      child: Text(
        badge,
        style: YkTypography.caption(context).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPresentiel(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.outlined,
      onTap: onSelectPresentiel,
      child: Row(
        children: [
          Icon(Icons.groups_rounded, color: YkColors.textSecondary(context)),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentielLabel!,
                  style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                ),
                if (presentielDescription != null)
                  Text(
                    presentielDescription!,
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: YkColors.textTertiary(context)),
        ],
      ),
    );
  }
}
