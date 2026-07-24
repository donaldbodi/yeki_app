import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Variante de [YkFab] — CDC_DESIGN §5.3.1.
enum YkFabVariant { regular, extended, small }

/// Bouton d'action flottant — CDC_DESIGN §5.3.1.
///
/// Remplace visuellement `lib/widgets/yeki_fabs.dart` (18 couleurs en
/// dur) — ce fichier reste `@Deprecated`, non supprimé : il embarque une
/// fonctionnalité complète (enregistrement audio + upload + soumission
/// forum) hors périmètre de ce composant, migration d'écran différée
/// (décision actée, voir P4.7).
class YkFab extends StatelessWidget {
  const YkFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = YkFabVariant.regular,
    this.backgroundColor,
  }) : assert(
         variant != YkFabVariant.extended || label != '',
         'YkFab.extended affiche le libellé — il ne peut pas être vide.',
       );

  final IconData icon;

  /// Toujours le libellé Semantics ; visible uniquement en
  /// [YkFabVariant.extended].
  final String label;
  final VoidCallback? onPressed;
  final YkFabVariant variant;

  /// Couleur d'accent (ex. couleur de cours), reçue de l'appelant —
  /// jamais lue depuis `YkCourseColors.palette` directement.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? YkColors.accent(context);
    final fg = YkColors.onAccent(context);

    switch (variant) {
      case YkFabVariant.regular:
        return Semantics(
          button: true,
          label: label,
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: bg,
            foregroundColor: fg,
            tooltip: label,
            child: Icon(icon),
          ),
        );
      case YkFabVariant.small:
        return Semantics(
          button: true,
          label: label,
          child: FloatingActionButton.small(
            onPressed: onPressed,
            backgroundColor: bg,
            foregroundColor: fg,
            tooltip: label,
            child: Icon(icon),
          ),
        );
      case YkFabVariant.extended:
        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: bg,
          foregroundColor: fg,
          icon: Icon(icon),
          label: Text(label),
        );
    }
  }
}
