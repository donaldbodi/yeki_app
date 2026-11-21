// lib/core/design/components/containers/yk_gradient_app_bar.dart
//
// AppBar habillée du dégradé de marque (`primary800→primary700→primary500`,
// même famille que les en-têtes Admin Général/Historique/Notifications
// d'un ticket antérieur) — extrait ici pour être réutilisé par toutes les
// pages qui n'avaient jusqu'ici qu'un `AppBar` Material par défaut
// (Paramètres, Édition profil, Paiement, Recharge, Retrait, etc.), sans
// changer aucun comportement de navigation (bouton retour/actions
// inchangés, seulement re-habillés).
//
// [gradient] optionnel (ticket revêtement maquette) : permet à un écran
// avec sa propre couleur d'accent réelle (ex. la couleur du cours sur
// `lecture_lecon_page.dart`) de réutiliser ce composant au lieu de
// dupliquer un `Container(decoration: BoxDecoration(...))` local — évite
// une violation de la règle 2 (style en dur hors `lib/core/design/`) tout
// en préservant le dégradé de marque par défaut pour tous les autres
// appelants (paramètre non fourni = comportement inchangé).

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class YkGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const YkGradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle,
    this.gradient,
    this.bottom,
  });

  final String? title;

  /// Prioritaire sur [title] si fourni (ex. titre + badge à côté).
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool? centerTitle;

  /// Dégradé de fond — défaut : dégradé de marque `primary800→700→500`.
  final Gradient? gradient;

  /// Barre inférieure (ex. indicateur de progression de lecture).
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: YkColors.textOnPrimary,
      centerTitle: centerTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [YkColors.primary800, YkColors.primary700, YkColors.primary500],
              ),
        ),
      ),
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
