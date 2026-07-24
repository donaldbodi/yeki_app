import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Ton visuel du bouton — CDC_DESIGN §5.3.1.
enum YkButtonVariant { primary, secondary, tertiary, ghost, destructive }

/// Taille du bouton.
enum YkButtonSize { sm, md, lg }

/// Position de l'icône par rapport au libellé (ignorée si [YkButton.icon]
/// est nul).
enum YkButtonIconPosition { leading, trailing, only }

/// Bouton d'action — CDC_DESIGN §5.3.1.
///
/// `isLoading` fige la largeur du bouton (le libellé/l'icône restent en
/// place mais invisibles, un indicateur de chargement est superposé) pour
/// éviter tout saut de mise en page pendant l'attente réseau.
class YkButton extends StatelessWidget {
  const YkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = YkButtonVariant.primary,
    this.size = YkButtonSize.md,
    this.icon,
    this.iconPosition = YkButtonIconPosition.leading,
    this.isLoading = false,
    this.isEnabled = true,
    this.semanticLabel,
  });

  /// Libellé visible (sauf si [iconPosition] vaut
  /// [YkButtonIconPosition.only], auquel cas il reste le libellé
  /// d'accessibilité — voir [semanticLabel]).
  final String label;
  final VoidCallback? onPressed;
  final YkButtonVariant variant;
  final YkButtonSize size;
  final IconData? icon;
  final YkButtonIconPosition iconPosition;

  /// Spinner superposé, interactions désactivées, taille inchangée.
  final bool isLoading;
  final bool isEnabled;

  /// Libellé d'accessibilité si différent de [label] (utile en mode
  /// [YkButtonIconPosition.only]).
  final String? semanticLabel;

  double get _height => switch (size) {
    YkButtonSize.sm => 36,
    YkButtonSize.md => 44,
    YkButtonSize.lg => 52,
  };

  double get _iconSize => switch (size) {
    YkButtonSize.sm => 16,
    YkButtonSize.md => 18,
    YkButtonSize.lg => 20,
  };

  double get _horizontalPadding => switch (size) {
    YkButtonSize.sm => YkSpacing.sm,
    YkButtonSize.md => YkSpacing.md,
    YkButtonSize.lg => YkSpacing.lg,
  };

  bool get _iconOnly => icon != null && iconPosition == YkButtonIconPosition.only;

  ({Color background, Color foreground, Color? border}) _colors(BuildContext context) {
    final accent = YkColors.accent(context);
    final onAccent = YkColors.onAccent(context);
    final dark = YkColors.isDark(context);
    switch (variant) {
      case YkButtonVariant.primary:
        return (background: accent, foreground: onAccent, border: null);
      case YkButtonVariant.secondary:
        return (
          background: dark ? YkColors.primary800 : YkColors.primary100,
          foreground: accent,
          border: null,
        );
      case YkButtonVariant.tertiary:
        return (background: Colors.transparent, foreground: accent, border: accent);
      case YkButtonVariant.ghost:
        return (background: Colors.transparent, foreground: accent, border: null);
      case YkButtonVariant.destructive:
        return (background: YkColors.error, foreground: YkColors.textOnPrimary, border: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading && onPressed != null;
    final colors = _colors(context);
    final background = enabled ? colors.background : colors.background.withValues(alpha: 0.4);
    final foreground = enabled ? colors.foreground : colors.foreground.withValues(alpha: 0.4);
    final border = colors.border;

    final content = _iconOnly
        ? Icon(icon, size: _iconSize, color: foreground)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && iconPosition == YkButtonIconPosition.leading) ...[
                Icon(icon, size: _iconSize, color: foreground),
                SizedBox(width: YkSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: YkTypography.label(context).copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null && iconPosition == YkButtonIconPosition.trailing) ...[
                SizedBox(width: YkSpacing.xs),
                Icon(icon, size: _iconSize, color: foreground),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(YkRadius.sm),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(YkRadius.sm),
          focusColor: colors.foreground.withValues(alpha: 0.12),
          hoverColor: colors.foreground.withValues(alpha: 0.08),
          highlightColor: colors.foreground.withValues(alpha: 0.16),
          child: Container(
            height: _height,
            padding: EdgeInsets.symmetric(horizontal: _iconOnly ? 0 : _horizontalPadding),
            width: _iconOnly ? _height : null,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(YkRadius.sm),
              border: border != null ? Border.all(color: border, width: 1.5) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: isLoading ? 0 : 1, child: content),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
