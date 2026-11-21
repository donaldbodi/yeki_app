import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Un onglet, avec badge optionnel.
class YkTabItem {
  const YkTabItem({required this.label, this.badge});
  final String label;
  final int? badge;
}

/// Onglets — CDC_DESIGN §5.3.3 : défilables si nécessaire, indicateur
/// animé, badge par onglet. Unifie les 2 implémentations concurrentes
/// trouvées (`cours_detail_page.dart`, `detail_cours_enseignant.dart`)
/// pour les mêmes 4 onglets Leçons/Exercices/Devoirs/Forum — écrans non
/// migrés dans ce ticket.
///
/// Le `TabController` reste possédé par l'appelant (comme
/// `GlobalKey<FormState>`/`TextEditingController` ailleurs dans le
/// projet), pour rester synchronisé avec un `TabBarView` externe.
class YkTabs extends StatelessWidget implements PreferredSizeWidget {
  const YkTabs({super.key, required this.controller, required this.tabs, this.activeColor});

  final TabController controller;
  final List<YkTabItem> tabs;

  /// Couleur du soulignement/libellé actif — `null` (défaut, comportement
  /// inchangé partout où ce paramètre n'est pas fourni) retombe sur
  /// `YkColors.accent(context)`. Introduit pour que `CoursDetailTabs`
  /// puisse teinter la barre d'onglets avec la couleur du cours consulté.
  final Color? activeColor;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final couleur = activeColor ?? YkColors.accent(context);
    return Material(
      color: YkColors.surface(context),
      child: TabBar(
        controller: controller,
        isScrollable: tabs.length > 4,
        // Maquette « 09 · Détail cours » : simple soulignement net sous
        // le LABEL (border-bottom 2.5px), pas l'indicateur Material 3
        // par défaut (remplissage arrondi pleine cellule) — indicateur
        // explicite pour un rendu identique.
        indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 2.5, color: couleur)),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: couleur,
        unselectedLabelColor: YkColors.textSecondary(context),
        labelStyle: YkTypography.label(context),
        tabs: [
          for (final tab in tabs)
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.label),
                  if (tab.badge != null && tab.badge! > 0) ...[
                    SizedBox(width: YkSpacing.xxs),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.xxs, vertical: 1),
                      decoration: BoxDecoration(
                        color: YkColors.error,
                        borderRadius: BorderRadius.circular(YkRadius.full),
                      ),
                      child: Text(
                        '${tab.badge}',
                        style: YkTypography.caption(context).copyWith(color: YkColors.textOnPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Épingle un [child] à hauteur fixe dans le `headerSliverBuilder` d'un
/// `NestedScrollView` — pensé pour y loger un [YkTabs] au-dessus d'un
/// `TabBarView`. Extrait après 3 copies quasi identiques d'un
/// `_TabsHeaderDelegate` privé (`formation_detail_page.dart`,
/// `detail_departement_page.dart`, `detail_cours_enseignant.dart`, P11.2/
/// P11.3) — remplace ces 3 copies plutôt que d'en ajouter une 4e (P11.5).
class YkPinnedHeader extends SliverPersistentHeaderDelegate {
  const YkPinnedHeader({required this.child, this.height = 64});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant YkPinnedHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
