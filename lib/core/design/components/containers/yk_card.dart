import 'dart:ui';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Ton visuel de [YkCard] — CDC_DESIGN §5.3.3.
enum YkCardVariant { elevated, filled, outlined, glass }

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
  });

  final Widget child;
  final YkCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Couleur de cours en accent (bordure/fond teinté), reçue de l'appelant.
  final Color? accentColor;

  /// Libellé Semantics si la carte est cliquable ; sans objet sinon.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(YkRadius.md);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(YkSpacing.md),
      child: child,
    );

    Widget card;
    switch (variant) {
      case YkCardVariant.elevated:
        card = Container(
          decoration: BoxDecoration(
            color: YkColors.surface(context),
            borderRadius: radius,
            boxShadow: YkElevation.e1,
            border: accentColor != null ? Border.all(color: accentColor!, width: 1) : null,
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
