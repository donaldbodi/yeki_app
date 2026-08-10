import 'dart:ui';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Ton visuel de [YkCard] — CDC_DESIGN §5.3.3.
///
/// [tinted] : même rendu qu'[elevated] (fond/ombre/rayon identiques) mais
/// la bordure adopte `accentColor` au lieu de rester neutre — introduit
/// pour que la couleur d'un cours soit visible sur les cartes de contenu
/// de son « univers » (leçons/exercices/devoirs/forum) sans changer le
/// comportement par défaut d'[elevated], utilisé massivement ailleurs.
enum YkCardVariant { elevated, filled, outlined, glass, tinted }

/// Conteneur de carte — CDC_DESIGN §5.3.3.
///
/// Accepte une [accentColor] optionnelle (couleur de cours) : reçue depuis
/// l'API appelante, jamais lue depuis `YkCourseColors.palette` directement
/// (règle métier §3.3, actée en P4.1 — cette palette n'alimente que le
/// sélecteur de couleur des formulaires de création/modification de cours).
class YkCard extends StatelessWidget {
  const YkCard({
    super.key,
    required this.child,
    this.variant = YkCardVariant.elevated,
    this.onTap,
    this.padding,
    this.accentColor,
    this.semanticLabel,
    this.gradient,
  });

  final Widget child;
  final YkCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Couleur de cours en accent (bordure/fond teinté), reçue de l'appelant.
  final Color? accentColor;

  /// Libellé Semantics si la carte est cliquable ; sans objet sinon.
  final String? semanticLabel;

  /// Remplissage en dégradé (carte « héro », ex. reprise de lecture mise en
  /// avant) — uniquement pris en compte pour [YkCardVariant.elevated].
  /// Toujours construit à partir de tokens `YkColors` par l'appelant,
  /// jamais une valeur inventée.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    // `YkRadius.lg` (20) — le rayon que le token lui-même documente pour
    // « grande carte » (`radius.dart`), pas `.md` (16, plutôt bouton/tuile
    // interne) : ce contraste de rayon entre la carte et son contenu
    // (icône, avatar) est ce que la maquette utilise systématiquement.
    final radius = BorderRadius.circular(YkRadius.lg);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(YkSpacing.md),
      child: child,
    );

    Widget card;
    switch (variant) {
      case YkCardVariant.elevated:
        card = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: gradient == null ? YkColors.surface(context) : null,
            gradient: gradient,
            borderRadius: radius,
            boxShadow: YkElevation.e1,
            // Bordure neutre systématique (maquette : la couleur du cours
            // reste confinée à la tuile d'icône/badge/barre de progression,
            // jamais à la bordure de la carte elle-même) — `accentColor`
            // n'affecte plus ce variant, seulement `filled`/`outlined`/`glass`.
            border: Border.all(color: YkColors.border(context), width: 1),
          ),
          child: content,
        );
      case YkCardVariant.tinted:
        card = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: gradient == null ? YkColors.surface(context) : null,
            gradient: gradient,
            borderRadius: radius,
            boxShadow: YkElevation.e1,
            border: Border.all(color: accentColor ?? YkColors.border(context), width: 1),
          ),
          child: content,
        );
      case YkCardVariant.filled:
        card = Container(
          decoration: BoxDecoration(
            color: accentColor?.withValues(alpha: 0.1) ?? YkColors.surfaceVariant(context),
            borderRadius: radius,
          ),
          child: content,
        );
      case YkCardVariant.outlined:
        card = Container(
          decoration: BoxDecoration(
            color: YkColors.surface(context),
            borderRadius: radius,
            border: Border.all(color: accentColor ?? YkColors.border(context), width: 1),
          ),
          child: content,
        );
      case YkCardVariant.glass:
        card = ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: YkColors.surface(context).withValues(alpha: 0.6),
                borderRadius: radius,
                border: Border.all(
                  color: (accentColor ?? YkColors.surface(context)).withValues(alpha: 0.3),
                ),
                boxShadow: YkElevation.e2,
              ),
              child: content,
            ),
          ),
        );
    }

    if (onTap == null) return card;

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      ),
    );
  }
}
