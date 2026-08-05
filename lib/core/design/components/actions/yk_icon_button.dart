import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Ton visuel de [YkIconButton] — CDC_DESIGN §5.3.1.
enum YkIconButtonVariant { filled, tonal, outlined, ghost }

/// Bouton icône seul — CDC_DESIGN §5.3.1.
///
/// Cible tactile garantie de 48×48 dp, quelle que soit la taille visuelle
/// de l'icône (§6 accessibilité — cible ≥48 dp).
class YkIconButton extends StatelessWidget {
  const YkIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.variant = YkIconButtonVariant.ghost,
    this.iconSize = 20,
    this.isEnabled = true,
  }) : assert(label != '', 'YkIconButton exige un libellé Semantics non vide.');

  final IconData icon;
  final VoidCallback? onPressed;

  /// Libellé Semantics — obligatoire : sans lui ce bouton est inutilisable
  /// au lecteur d'écran (une icône seule ne porte aucun sens sémantique).
  final String label;
  final YkIconButtonVariant variant;
  final double iconSize;
  final bool isEnabled;

  static const double _tapTarget = 48;

  ({Color background, Color foreground}) _colors(BuildContext context) {
    final accent = YkColors.accent(context);
    final onAccent = YkColors.onAccent(context);
    final dark = YkColors.isDark(context);
    switch (variant) {
      case YkIconButtonVariant.filled:
        return (background: accent, foreground: onAccent);
      case YkIconButtonVariant.tonal:
        return (
          background: dark ? YkColors.primary800 : YkColors.primary100,
          foreground: accent,
        );
      case YkIconButtonVariant.outlined:
        return (background: Colors.transparent, foreground: accent);
      case YkIconButtonVariant.ghost:
        return (background: Colors.transparent, foreground: YkColors.textPrimary(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && onPressed != null;
    final colors = _colors(context);
    final background = enabled ? colors.background : colors.background.withValues(alpha: 0.4);
    final foreground = enabled ? colors.foreground : colors.foreground.withValues(alpha: 0.4);

    // `outlined` (retour/favori type maquette « 09 · Détail cours ») :
    // carré arrondi compact 34×34 (rayon 12, bordure fine), pas un
    // cercle 48×48 — la cible tactile 48×48 reste garantie (§6
    // accessibilité, l'`InkWell` couvre toujours la `SizedBox` externe
    // entière), seul le rendu VISUEL (fond+bordure) se recentre à 34×34
    // dans une `Material` imbriquée, transparente pour le tap.
    final isCompactOutline = variant == YkIconButtonVariant.outlined;
    final ShapeBorder shape = isCompactOutline
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YkRadius.md),
            side: BorderSide(color: YkColors.border(context)),
          )
        : const CircleBorder();

    final visual = Center(
      child: SizedBox(
        width: isCompactOutline ? 34 : _tapTarget,
        height: isCompactOutline ? 34 : _tapTarget,
        child: Material(
          color: background,
          shape: shape,
          child: Center(child: Icon(icon, size: iconSize, color: foreground)),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: shape,
          focusColor: colors.foreground.withValues(alpha: 0.12),
          hoverColor: colors.foreground.withValues(alpha: 0.08),
          highlightColor: colors.foreground.withValues(alpha: 0.16),
          child: SizedBox(width: _tapTarget, height: _tapTarget, child: visual),
        ),
      ),
    );
  }
}
