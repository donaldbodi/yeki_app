import 'package:flutter/material.dart';

import 'yk_button.dart';
import 'yk_icon_button.dart';

/// Bouton "Chercher un répétiteur" — CDC_DESIGN, posé aux 2 points
/// d'entrée exigés (`lecons_cours.dart`, `cours_detail_page.dart`, P11.7).
/// Garantit icône/libellé identiques aux deux endroits ; la navigation
/// reste à la charge de l'appelant (comme tout autre `Yk*` d'action —
/// aucun composant de ce dossier n'importe `go_router` directement).
///
/// [compact] : icône seule avec info-bulle — pour une barre déjà dense
/// (ex. l'en-tête de `cours_detail_page.dart`, retour + titre + ce
/// bouton) où le libellé complet déborderait.
class YkRepetiteurButton extends StatelessWidget {
  const YkRepetiteurButton({
    super.key,
    required this.onPressed,
    this.variant = YkButtonVariant.secondary,
    this.size = YkButtonSize.md,
    this.compact = false,
  });

  static const _label = 'Chercher un répétiteur';

  final VoidCallback onPressed;
  final YkButtonVariant variant;
  final YkButtonSize size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return YkIconButton(icon: Icons.groups_rounded, label: _label, onPressed: onPressed);
    }
    return YkButton(label: _label, icon: Icons.groups_rounded, variant: variant, size: size, onPressed: onPressed);
  }
}
