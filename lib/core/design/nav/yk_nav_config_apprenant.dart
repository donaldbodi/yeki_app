import 'package:flutter/material.dart';
import 'package:yeki/core/router/route_names.dart';

import 'yk_nav_destination.dart';

/// Destinations de l'interface Apprenant — CDC_DESIGN §4.2.1, recopiées
/// exactement (ordre, libellés, icônes).
///
/// Barre compacte (mobile) : Accueil, Cursus, Prépa Concours, Formations
/// — Devoirs et Forum en sont retirés (Phase 2, refonte écran par écran) :
/// tous deux restent pleinement fonctionnels comme onglets contextualisés
/// PAR COURS dans `CoursDetailTabs` (`cours_detail_page.dart`), la
/// destination globale ne faisait que dupliquer un point d'entrée déjà
/// couvert. Aucune destination n'est perdue en petit écran — elles
/// changent de porte d'entrée, pas d'existence (rail/navbar large + tiroir
/// « Plus » en compact).
///
/// Forum et Yéki IA (en tant que destination autonome, hors contexte d'un
/// cours) n'ont aujourd'hui aucune route globale — `null`, visibles mais
/// non cliquables (voir P4.6, décision actée).
final List<YkNavGroup> apprenantNavGroups = [
  const YkNavGroup(
    destinations: [
      YkNavDestination(
        label: 'Accueil',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        routeName: AppRoute.dashboardAccueil,
        inCompactBar: true,
      ),
    ],
  ),
  const YkNavGroup(
    title: 'Apprentissage',
    destinations: [
      YkNavDestination(
        label: 'Cursus',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        routeName: AppRoute.dashboardCursus,
        inCompactBar: true,
      ),
      YkNavDestination(
        label: 'Prépa Concours',
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        routeName: AppRoute.dashboardConcours,
        inCompactBar: true,
      ),
      YkNavDestination(
        label: 'Formations',
        icon: Icons.workspace_premium_outlined,
        selectedIcon: Icons.workspace_premium,
        routeName: AppRoute.dashboardFormations,
        inCompactBar: true,
      ),
    ],
  ),
  const YkNavGroup(
    title: 'Activité',
    destinations: [
      YkNavDestination(
        label: 'Devoirs',
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        routeName: AppRoute.dashboardDevoirs,
        badgeKey: 'devoirs',
      ),
      YkNavDestination(
        label: 'Olympiades',
        icon: Icons.military_tech_outlined,
        selectedIcon: Icons.military_tech,
        routeName: AppRoute.dashboardOlympiades,
        badgeKey: 'olympiade',
      ),
      YkNavDestination(
        label: 'Forum',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        badgeKey: 'forum',
        // TODO(nav): ForumPage n'existe qu'en widget embarqué par cours
        // aujourd'hui, jamais en destination globale — §4.2.1, dest. 7.
      ),
      YkNavDestination(
        label: 'Yéki IA',
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        // TODO(nav): route `iaChat` existante mais contextuelle
        // (nécessite un coursId) — pas une destination de nav autonome.
      ),
    ],
  ),
  const YkNavGroup(
    title: 'Compte',
    destinations: [
      YkNavDestination(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        routeName: AppRoute.notifications,
        badgeKey: 'notifications',
      ),
      YkNavDestination(
        label: 'Portefeuille',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        routeName: AppRoute.wallet,
        badgeKey: 'wallet',
      ),
    ],
  ),
];
