// lib/views/pages/enseignants/enseignant_shell.dart
// ═══════════════════════════════════════════════════════════════════════════
// COQUE ENSEIGNANT — chrome (navigation latérale/basse) uniquement.
// Remplace l'ancien EnseignantHomePage : celui-ci mélangeait le chrome
// avec (1) un appel API redondant pour deviner quel dashboard afficher
// et (2) le fetch de profil/cours transmis à DashboardPrincipalPage.
// Ici : (1) est supprimé (le rôle vient de `authState`, déjà en cache,
// et le choix du dashboard concret est résolu par guards.dart/app_router,
// pas par ce widget) ; (2) est supprimé (DashboardPrincipalPage est
// devenu autonome). Le contenu de la branche « Accueil » est fourni par
// `navigationShell` lui-même (StatefulShellRoute.indexedStack) — ce
// widget ne sait pas et n'a pas besoin de savoir lequel des 5 dashboards
// concrets y est actuellement affiché.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/containers/yk_brand_app_bar.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/providers/current_user_provider.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart'
    show RoleEnseignant, roleEnseignantFromBackend;

/// P13.1 : migré hors de `yeki_design_system.dart`/`yeki_design_extension.dart`
/// (anciens, retirés) — comportement/structure INCHANGÉS (migration minimale
/// tokens seulement, arbitrage tranché avec l'utilisateur : une vraie refonte
/// P5.0 de cette coquille reste un ticket à part). Seuils responsive
/// reproduits ici à l'identique (600/1024) plutôt que mappés sur
/// `YkBreakpoints` (dont les seuils 600/905/1240 diffèrent — un mappage par
/// nom aurait décalé les points de bascule mobile/tablette/desktop).
const double _kMobileMax = 600.0;
const double _kTabletMax = 1024.0;
bool _isMobile(BuildContext context) => MediaQuery.sizeOf(context).width <= _kMobileMax;
bool _isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width > _kMobileMax && MediaQuery.sizeOf(context).width <= _kTabletMax;
bool _isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width > _kTabletMax;
double _dynamicPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width > _kTabletMax) return 32.0;
  if (width > _kMobileMax) return 24.0;
  return 16.0;
}

const _kShadowStrong = [
  BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 12)),
];

/// Reproduction fidèle de l'ancien `YekiAvatar` (CircleAvatar simple).
class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl, this.initials, this.backgroundColor, this.radius = 20, this.showBorder = false});

  final String? imageUrl;
  final String? initials;
  final Color? backgroundColor;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? YkColors.accent(context).withValues(alpha: 0.1),
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initials ?? '?',
              style: TextStyle(color: YkColors.accent(context), fontWeight: FontWeight.bold, fontSize: radius * 0.7),
            )
          : null,
    );
    if (!showBorder) return avatar;
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: avatar,
    );
  }
}


class EnseignantShellPage extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const EnseignantShellPage({super.key, required this.navigationShell});

  @override
  ConsumerState<EnseignantShellPage> createState() => _EnseignantShellPageState();
}

class _EnseignantShellPageState extends ConsumerState<EnseignantShellPage> {
  final int _nbNotifs = 0;

  RoleEnseignant get _role => roleEnseignantFromBackend(authState.value.role);

  String _getRoleLabel(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:
        return 'Administrateur Général';
      case RoleEnseignant.enseignantAdministrateur:
        return 'Coordonnateur';
      case RoleEnseignant.enseignantCadre:
        return 'Cadre';
      case RoleEnseignant.enseignantPrincipal:
        return 'Principal';
      case RoleEnseignant.serviceClient:
        return 'Service Client';
      default:
        return 'Enseignant';
    }
  }

  // Couleurs de rôle alignées sur la maquette (`docs/maquette/YEKI Espace
  // Enseignant.dc.html`, sélecteur de rôle) — la migration précédente (hors
  // de l'ancien design system) avait conservé les valeurs ad hoc de
  // l'ancien fichier telles quelles, dont le mapping était en réalité
  // inversé par rapport à la maquette (vert sur Coordonnateur, or sur
  // Principal) : corrigé ici en même temps que le passage aux tokens.
  Color _getRoleColor(BuildContext context, RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:
        return YkColors.violet;
      case RoleEnseignant.enseignantAdministrateur:
        return YkColors.accent(context);
      case RoleEnseignant.enseignantCadre:
        return YkColors.info;
      case RoleEnseignant.enseignantPrincipal:
        return YkColors.success;
      case RoleEnseignant.serviceClient:
        return YkColors.error;
      default:
        // Enseignant Secondaire.
        return YkColors.gold(context);
    }
  }

  // Lu depuis le provider partagé (`current_user_provider.dart`) plutôt
  // que d'un fetch local propre à cette coquille — bug corrigé : la photo
  // de profil ne se répercutait jamais ici après une édition ailleurs
  // dans l'app (coquille persistante, jamais reconstruite par la
  // navigation vers /profile/edit et retour).
  String get _nomAffiche {
    final profil = ref.watch(currentUserProvider).valueOrNull;
    if (profil == null) return 'Enseignant';
    final fn = profil.firstName;
    final ln = profil.lastName;
    if (fn.isNotEmpty && ln.isNotEmpty) return '$fn $ln';
    if (fn.isNotEmpty) return fn;
    if (ln.isNotEmpty) return ln;
    return 'Enseignant';
  }

  String? get _avatarUrl => ref.watch(currentUserProvider).valueOrNull?.avatar;

  String get _initials {
    final n = _nomAffiche;
    if (n.isEmpty || n == 'Enseignant') return 'E';
    final parts = n.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final isTablet = _isTablet(context);
    final isDesktop = _isDesktop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDesktop ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        backgroundColor: YkColors.background(context),
        appBar: isDesktop ? null : _buildBrandAppBar(context),
        body: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
        bottomNavigationBar: isMobile || isTablet ? _buildFloatingNav(context) : null,
      ),
    );
  }

  // ─── LAYOUT DESKTOP ──────────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    final role = _role;

    return Row(
      children: [
        // ── Navigation latérale gauche ──────────────────────────────────
        Container(
          width: 260,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YkColors.surface(context),
            border: Border(
              right: BorderSide(color: YkColors.border(context), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / Brand
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: YkColors.accent(context),
                      borderRadius: BorderRadius.circular(YkRadius.xs),
                    ),
                    child: Center(
                      child: Text(
                        'Y',
                        style: TextStyle(
                          color: YkColors.textOnPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Yeki',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: YkColors.textPrimary(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Menu de navigation ────────────────────────────────────
              _buildNavItem(context, 0, Icons.grid_view_rounded, 'Accueil'),
              const SizedBox(height: 8),
              _buildNavItem(context, 1, Icons.history_rounded, 'Historique'),
              const SizedBox(height: 8),
              _buildNavItem(context, 2, Icons.person_rounded, 'Profil'),
              // Cadre uniquement : `repartir_et_crediter()` (commissions
              // formation/olympiade, apps/paiement/services.py) ne crédite
              // QUE `departement.cadre` — un principal n'a structurellement
              // rien à retirer (erreur de portée corrigée, ce ticket).
              if (role == RoleEnseignant.enseignantCadre) ...[
                const SizedBox(height: 8),
                _buildRevenusNavItem(context),
              ],

              const Spacer(),

              // ── Profil utilisateur ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: YkColors.background(context),
                  borderRadius: BorderRadius.circular(YkRadius.md),
                  border: Border.all(color: YkColors.border(context), width: 1),
                ),
                child: Row(
                  children: [
                    _Avatar(
                      imageUrl: _avatarUrl,
                      initials: _initials,
                      radius: 24,
                      backgroundColor: _getRoleColor(context, role).withValues(alpha: 0.3),
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nomAffiche,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: YkColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            _getRoleLabel(role),
                            style: TextStyle(
                              fontSize: 11,
                              color: YkColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Bouton déconnexion ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authState.clearSession();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Déconnexion'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: YkColors.border(context)),
                    foregroundColor: YkColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Contenu principal ───────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
                decoration: BoxDecoration(
                  color: YkColors.surface(context),
                  border: Border(
                    bottom: BorderSide(color: YkColors.border(context), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getPageTitle(widget.navigationShell.currentIndex),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: YkColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: YkColors.textPrimary(context),
                            size: 24,
                          ),
                          if (_nbNotifs > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: YkColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_nbNotifs',
                                    style: TextStyle(
                                      color: YkColors.textOnPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => context.pushNamed(AppRoute.notifications),
                    ),
                  ],
                ),
              ),

              // ── Contenu de la branche active ──────────────────────────
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ITEM « MES REVENUS » (desktop) ──────────────────────────────────────
  // Bug corrigé (modèle économique non opérationnel) : `WalletPage`/
  // `RetraitPage` sont déjà construites et fonctionnelles (elles créditent
  // réellement le compte du cadre à chaque vente de formation, `apps/
  // paiement/services.py::repartir_et_crediter`) mais aucun point d'entrée
  // n'y menait côté enseignant — visible uniquement au cadre, seul rôle
  // qui touche réellement une commission (`repartir_et_crediter` ne
  // crédite que `departement.cadre`, jamais un principal).
  // `context.pushNamed` (pas `goBranch` : ce n'est pas une branche du
  // shell, une route poussée au-dessus, comme `/profile`).
  Widget _buildRevenusNavItem(BuildContext context) {
    final secondary = YkColors.textSecondary(context);
    return InkWell(
      onTap: () => context.pushNamed(AppRoute.wallet),
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: secondary, size: 22),
            const SizedBox(width: 14),
            Text('Mes revenus', style: YkTypography.bodyMd(context).copyWith(color: secondary)),
          ],
        ),
      ),
    );
  }

  // ─── ITEM DE NAVIGATION DESKTOP ──────────────────────────────────────────
  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final accent = YkColors.accent(context);
    final secondary = YkColors.textSecondary(context);

    return InkWell(
      onTap: () => widget.navigationShell.goBranch(index),
      borderRadius: BorderRadius.circular(YkRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(YkRadius.md),
          border: isSelected ? Border.all(color: accent.withValues(alpha: 0.2), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? accent : secondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : secondary,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TITRE DE PAGE ──────────────────────────────────────────────────────
  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Historique';
      case 2:
        return 'Profil';
      default:
        return 'Accueil';
    }
  }

  // ─── EN-TÊTE MOBILE/TABLETTE ─────────────────────────────────────────────
  // « Yéki » seul à gauche, actions à droite (façon WhatsApp), commun avec
  // l'espace apprenant : `YkBrandAppBar`. Le nom et le rôle sont repris dans
  // le menu de l'avatar et dans la salutation de l'onglet Accueil.
  PreferredSizeWidget _buildBrandAppBar(BuildContext context) {
    final role = _role;
    return YkBrandAppBar(
      actions: [
        // Cadre uniquement : `repartir_et_crediter()` ne crédite que
        // `departement.cadre`, un principal n'a rien à retirer.
        if (role == RoleEnseignant.enseignantCadre)
          YkBrandAppBarAction(
            icon: Icons.account_balance_wallet_outlined,
            tooltip: 'Mes revenus',
            onPressed: () => context.pushNamed(AppRoute.wallet),
          ),
        YkBrandAppBarAction(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          badge: _nbNotifs,
          onPressed: () => context.pushNamed(AppRoute.notifications),
        ),
      ],
      userName: _nomAffiche,
      roleLabel: _getRoleLabel(role),
      roleColor: _getRoleColor(context, role),
      avatarUrl: _avatarUrl,
      onProfile: () => widget.navigationShell.goBranch(2),
      onSettings: () => context.pushNamed(AppRoute.settings),
      onLogout: () => authState.clearSession(),
    );
  }

  // ─── LAYOUT MOBILE/TABLETTE ──────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // ── Fond décoratif ──────────────────────────────────────────────
        // Part du bleu de l'en-tête (`primary700`) pour le prolonger sans
        // rupture de teinte.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 240,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [YkColors.primary700, YkColors.primary600, YkColors.primary500],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(YkRadius.xl * 1.5),
                bottomRight: Radius.circular(YkRadius.xl * 1.5),
              ),
            ),
          ),
        ),

        // ── Contenu principal ──────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              if (widget.navigationShell.currentIndex == 0) _buildSalutation(context),
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SALUTATION (onglet Accueil) ────────────────────────────────────────
  Widget _buildSalutation(BuildContext context) {
    final role = _role;
    return Padding(
      padding: EdgeInsets.fromLTRB(_dynamicPadding(context), 14, _dynamicPadding(context), 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $_nomAffiche 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: YkTypography.h4(context).copyWith(color: YkColors.textOnPrimary),
            ),
            const SizedBox(height: 6),
            YkRoleChip(
              label: _getRoleLabel(role),
              color: _getRoleColor(context, role),
              onDark: true,
            ),
          ],
        ),
      ),
    );
  }

  // ─── NAVIGATION FLOTTANTE MOBILE/TABLETTE ──────────────────────────────
  // Fond bleu YEKI plein et blanc lisible : l'ancienne pilule translucide
  // (onglet actif en bleu sur bleu-gris, inactifs en gris pâle) manquait de
  // contraste. Onglet actif : pastille blanche, icône et libellé bleus ;
  // inactifs : icône et libellé blancs.
  Widget _buildFloatingNav(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Accueil'),
      (Icons.history_rounded, Icons.history_outlined, 'Historique'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
    ];

    final isMobile = _isMobile(context);
    final currentIndex = widget.navigationShell.currentIndex;
    final dark = YkColors.isDark(context);
    final fond = dark ? YkColors.surfaceVariant(context) : YkColors.primary800;
    final pastille = dark ? YkColors.primary300 : YkColors.textOnPrimary;
    final surPastille = dark ? YkColors.primary900 : YkColors.primary700;
    final inactif = YkColors.textOnPrimary.withValues(alpha: 0.92);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        0,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
      ),
      child: Container(
        height: isMobile ? 68 : 76,
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(32),
          border: dark ? Border.all(color: YkColors.border(context)) : null,
          boxShadow: _kShadowStrong,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = currentIndex == i;
            final couleur = isSelected ? surPastille : inactif;

            final icone = Icon(
              isSelected ? item.$1 : item.$2,
              color: couleur,
              size: isMobile ? 22 : 24,
            );
            final libelle = Text(
              item.$3,
              style: TextStyle(
                color: couleur,
                fontSize: isSelected ? (isMobile ? 12 : 13) : (isMobile ? 10.5 : 11.5),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            );

            return Semantics(
              button: true,
              selected: isSelected,
              label: item.$3,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => widget.navigationShell.goBranch(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? (isMobile ? 16 : 20) : 14,
                    vertical: isSelected ? 9 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? pastille : Colors.transparent,
                    borderRadius: BorderRadius.circular(YkRadius.xl),
                  ),
                  child: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [icone, SizedBox(width: isMobile ? 6 : 8), libelle],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [icone, const SizedBox(height: 2), libelle],
                        ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
