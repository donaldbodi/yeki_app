import 'package:flutter/material.dart';
import 'package:yeki/core/router/route_names.dart';

import 'yk_nav_destination.dart';

const Set<String> _tousLesGrades = {
  'admin',
  'service_client',
  'enseignant_admin',
  'enseignant_cadre',
  'enseignant_principal',
  'enseignant',
};
const Set<String> _enseignantPrincipal = {'enseignant', 'enseignant_principal'};
const Set<String> _cadre = {'enseignant_cadre'};
const Set<String> _enseignantAdmin = {'enseignant_admin'};
const Set<String> _enseignantPrincipalCadre = {'enseignant', 'enseignant_principal', 'enseignant_cadre'};
const Set<String> _serviceClient = {'service_client'};
const Set<String> _adminSeul = {'admin'};

class _Entry {
  const _Entry(this.groupTitle, this.destination, this.roles);
  final String? groupTitle;
  final YkNavDestination destination;
  final Set<String> roles;
}

/// Destinations de l'interface Enseignant — CDC_DESIGN §4.2.2, recopiées
/// exactement (ordre, libellés, colonne « visible pour »).
///
/// **Discordance trouvée, signalée (règle 8)** : le CDC classe « Demandes
/// d'accès » comme visible pour « Enseignant Admin », mais la route
/// existante `cadreGestionDemandes` est aujourd'hui réservée au rôle
/// `enseignant_cadre` (`RouteAccess`, `guards.dart`). Comme cette route
/// exige de toute façon un `departementId` (paramètre dynamique non
/// résolvable depuis une config de navigation statique), la destination
/// est traitée comme non câblée (`routeName: null`) des deux côtés — la
/// discordance de rôle n'a donc pas d'impact pratique ici, mais devra
/// être tranchée avant que cet écran soit réellement branché.
///
/// Même traitement, mêmes raisons (route à paramètre dynamique non
/// résolvable statiquement) pour « Mon département »
/// (`coordinationDepartementDetail`/`cadreDepartementDetail` exigent un
/// `departementId`) et « Mon parcours » (`adminParcoursDetail` exige un
/// `parcoursId`).
const List<_Entry> _entries = [
  _Entry(
    null,
    YkNavDestination(
      label: 'Tableau de bord',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      routeName: AppRoute.enseignantDashboard,
    ),
    _tousLesGrades,
  ),
  _Entry(
    'Enseignement',
    YkNavDestination(
      label: 'Mes cours',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      // TODO(nav): "Mes cours" est un onglet interne aux dashboards par
      // rôle aujourd'hui, jamais une route dédiée — §4.2.2, dest. 2.
    ),
    _enseignantPrincipal,
  ),
  _Entry(
    'Enseignement',
    YkNavDestination(
      label: 'Mon département',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      // TODO(nav): route existante mais paramétrée (departementId) —
      // voir note de tête de fichier.
    ),
    _cadre,
  ),
  _Entry(
    'Enseignement',
    YkNavDestination(
      label: 'Mon parcours',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route,
      // TODO(nav): route existante mais paramétrée (parcoursId) — voir
      // note de tête de fichier.
    ),
    _enseignantAdmin,
  ),
  _Entry(
    'Enseignement',
    YkNavDestination(
      label: 'Devoirs',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      badgeKey: 'devoirs',
      // TODO(nav): aucune route Devoirs côté enseignant aujourd'hui
      // (DevoirsPage n'est câblée qu'apprenant) — §4.2.2, dest. 5.
    ),
    _enseignantPrincipalCadre,
  ),
  _Entry(
    'Enseignement',
    YkNavDestination(
      label: 'Olympiades',
      icon: Icons.military_tech_outlined,
      selectedIcon: Icons.military_tech,
      // TODO(nav): gérées en onglet interne de cadre_dashboard_page.dart
      // aujourd'hui, jamais en route dédiée — §4.2.2, dest. 6.
    ),
    _cadre,
  ),
  _Entry(
    'Administration',
    YkNavDestination(
      label: "Demandes d'accès",
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      // TODO(nav): route paramétrée — voir note de tête de fichier.
    ),
    _enseignantAdmin,
  ),
  _Entry(
    'Administration',
    YkNavDestination(
      label: 'Paiements à valider',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      // TODO(nav): dashboard Service Client construit en P9.5 —
      // §4.2.2, dest. 8.
    ),
    _serviceClient,
  ),
  _Entry(
    'Administration',
    YkNavDestination(
      label: 'Gestion des répétiteurs',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
      // TODO(nav): dashboard Service Client construit en P9.5 — la route
      // `repetiteurs` existante est la recherche apprenant, sans rapport.
    ),
    _serviceClient,
  ),
  _Entry(
    'Administration',
    YkNavDestination(
      label: 'Administration générale',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      routeName: AppRoute.enseignantAdmin,
    ),
    _adminSeul,
  ),
  _Entry(
    null,
    YkNavDestination(
      label: 'Historique',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      routeName: AppRoute.enseignantHistorique,
    ),
    _tousLesGrades,
  ),
  _Entry(
    null,
    YkNavDestination(
      label: 'Forum',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
      badgeKey: 'forum',
      // TODO(nav): pas de destination Forum globale enseignant
      // aujourd'hui (même constat que côté apprenant) — §4.2.2, dest. 12.
    ),
    _tousLesGrades,
  ),
];

/// Construit les groupes de destinations visibles pour [role] — seule
/// différence entre les grades enseignant, comme le veut le CDC (« un
/// composant, deux fichiers de configuration »). `inCompactBar` est
/// recalculé ici (pas figé en `const`) : le CDC ne fixe pas de
/// sous-ensemble explicite pour l'enseignant (contrairement à
/// l'apprenant) — décision raisonnable, cohérente avec le principe
/// général déjà énoncé : les 4 premières destinations visibles pour ce
/// rôle (dans l'ordre du tableau CDC) vont dans la barre du bas, le
/// reste dans le menu avatar.
List<YkNavGroup> enseignantNavGroups(String role) {
  final visible = _entries.where((e) => e.roles.contains(role)).toList();

  final compactCount = visible.length < 4 ? visible.length : 4;
  final withCompactFlag = <_Entry>[
    for (var i = 0; i < visible.length; i++)
      _Entry(
        visible[i].groupTitle,
        visible[i].destination.copyWith(inCompactBar: i < compactCount),
        visible[i].roles,
      ),
  ];

  final order = <String?>[];
  final byGroup = <String?, List<YkNavDestination>>{};
  for (final entry in withCompactFlag) {
    if (!byGroup.containsKey(entry.groupTitle)) {
      byGroup[entry.groupTitle] = [];
      order.add(entry.groupTitle);
    }
    byGroup[entry.groupTitle]!.add(entry.destination);
  }

  return [for (final title in order) YkNavGroup(title: title, destinations: byGroup[title]!)];
}
