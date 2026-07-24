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
  const YkTabs({super.key, required this.controller, required this.tabs});

  final TabController controller;
  final List<YkTabItem> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YkColors.surface(context),
      child: TabBar(
        controller: controller,
        isScrollable: tabs.length > 4,
        indicatorColor: YkColors.accent(context),
        labelColor: YkColors.accent(context),
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
