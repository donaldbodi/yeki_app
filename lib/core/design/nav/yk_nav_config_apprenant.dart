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
/// cours) ont été retirés de cette liste (demande explicite) — aucune
/// route globale n'existe pour ni l'un ni l'autre (voir P4.6), et les
/// deux restent pleinement accessibles dans leur contexte réel (Forum
/// par cours, Yéki IA via une route contextuelle).
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
      // « Forum » et « Yéki IA » retirés (demande explicite) : ni l'un ni
      // l'autre n'a jamais eu de route globale câblée (voir l'historique
      // de ce fichier) — Forum reste pleinement fonctionnel comme onglet
      // contextualisé PAR COURS (`CoursDetailTabs`), Yéki IA comme route
      // `iaChat` contextuelle (nécessite un coursId) — aucune capacité
      // perdue, seulement 2 destinations mortes retirées du tiroir.
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
