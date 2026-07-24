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
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/theme/yeki_design_extension.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart'
    show RoleEnseignant, roleEnseignantFromBackend;

class EnseignantShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const EnseignantShellPage({super.key, required this.navigationShell});

  @override
  State<EnseignantShellPage> createState() => _EnseignantShellPageState();
}

class _EnseignantShellPageState extends State<EnseignantShellPage> {
  Map<String, dynamic> _profil = {};
  final int _nbNotifs = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final res = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _profil = data);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

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
      default:
        return 'Enseignant';
    }
  }

  Color _getRoleColor(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:
        return YekiRoleColors.admin;
      case RoleEnseignant.enseignantAdministrateur:
        return YekiRoleColors.enseignant;
      case RoleEnseignant.enseignantCadre:
        return YekiRoleColors.cadre;
      case RoleEnseignant.enseignantPrincipal:
        return YekiRoleColors.principal;
      default:
        return YekiColors.primaryLight;
    }
  }

  String get _nomAffiche {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    if (fn.isNotEmpty && ln.isNotEmpty) return '$fn $ln';
    if (fn.isNotEmpty) return fn;
    if (ln.isNotEmpty) return ln;
    return 'Enseignant';
  }

  String? get _avatarUrl => _profil['avatar']?.toString();

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
    final isMobile = YekiResponsive.isMobile(context);
    final isTablet = YekiResponsive.isTablet(context);
    final isDesktop = YekiResponsive.isDesktop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDesktop ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        backgroundColor: YekiColors.bgLight,
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        bottomNavigationBar: isMobile || isTablet ? _buildFloatingNav() : null,
      ),
    );
  }

  // ─── LAYOUT DESKTOP ──────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    final role = _role;

    return Row(
      children: [
        // ── Navigation latérale gauche ──────────────────────────────────
        Container(
          width: 260,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YekiColors.white,
            border: Border(
              right: BorderSide(color: YekiColors.borderLight, width: 1),
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
                      color: YekiColors.primary,
                      borderRadius: YekiRadius.radiusSm,
                    ),
                    child: const Center(
                      child: Text(
                        'Y',
                        style: TextStyle(
                          color: YekiColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Yeki',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: YekiColors.textDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Menu de navigation ────────────────────────────────────
              _buildNavItem(0, Icons.grid_view_rounded, 'Accueil'),
              const SizedBox(height: 8),
              _buildNavItem(1, Icons.history_rounded, 'Historique'),
              const SizedBox(height: 8),
              _buildNavItem(2, Icons.person_rounded, 'Profil'),

              const Spacer(),

              // ── Profil utilisateur ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: YekiColors.bgLight,
                  borderRadius: YekiRadius.radiusMd,
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    YekiAvatar(
                      imageUrl: _avatarUrl,
                      initials: _initials,
                      radius: 24,
                      backgroundColor: _getRoleColor(role).withValues(alpha: 0.3),
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nomAffiche,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: YekiColors.textDark,
                            ),
                          ),
                          Text(
                            _getRoleLabel(role),
                            style: const TextStyle(
                              fontSize: 11,
                              color: YekiColors.textMedium,
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
                    side: const BorderSide(color: YekiColors.borderLight),
                    foregroundColor: YekiColors.textMedium,
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
                  color: YekiColors.white,
                  border: Border(
                    bottom: BorderSide(color: YekiColors.borderLight, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getPageTitle(widget.navigationShell.currentIndex),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: YekiColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: YekiColors.textDark,
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
                                  color: YekiColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_nbNotifs',
                                    style: const TextStyle(
                                      color: YekiColors.white,
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

  // ─── ITEM DE NAVIGATION DESKTOP ──────────────────────────────────────────
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.navigationShell.currentIndex == index;

    return InkWell(
      onTap: () => widget.navigationShell.goBranch(index),
      borderRadius: YekiRadius.radiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? YekiColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: YekiRadius.radiusMd,
          border: isSelected ? Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? YekiColors.primary : YekiColors.textMedium,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? YekiColors.primary : YekiColors.textMedium,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: YekiColors.primary,
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

  // ─── LAYOUT MOBILE/TABLETTE ──────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // ── Fond décoratif ──────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 240,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0D2A3A),
                  YekiColors.primaryDark,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(YekiRadius.lg * 1.5),
                bottomRight: Radius.circular(YekiRadius.lg * 1.5),
              ),
            ),
          ),
        ),

        // ── Contenu principal ──────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              _buildMobileHeader(),
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HEADER MOBILE ──────────────────────────────────────────────────────
  Widget _buildMobileHeader() {
    final role = _role;
    final roleColor = _getRoleColor(role);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        YekiResponsive.dynamicPadding(context),
        12,
        YekiResponsive.dynamicPadding(context),
        16,
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => widget.navigationShell.goBranch(2),
            child: Stack(
              children: [
                YekiAvatar(
                  imageUrl: _avatarUrl,
                  initials: _initials,
                  radius: 22,
                  backgroundColor: roleColor.withValues(alpha: 0.3),
                  showBorder: true,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: YekiColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: YekiColors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Infos utilisateur ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $_nomAffiche 👋',
                  style: TextStyle(
                    color: YekiColors.white,
                    fontSize: YekiResponsive.isMobile(context) ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                YekiRoleBadge(
                  role: _getRoleLabel(role),
                  fontSize: 10,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Bouton notifications ──────────────────────────────────────
          GestureDetector(
            onTap: () => context.pushNamed(AppRoute.notifications),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: YekiColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: YekiColors.white,
                    size: 20,
                  ),
                ),
                if (_nbNotifs > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: YekiColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_nbNotifs',
                          style: const TextStyle(
                            color: YekiColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NAVIGATION FLOTTANTE MOBILE/TABLETTE ──────────────────────────────
  Widget _buildFloatingNav() {
    final items = [
      (Icons.grid_view_rounded, Icons.grid_view_outlined, 'Accueil'),
      (Icons.history_rounded, Icons.history_outlined, 'Historique'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
    ];

    final isMobile = YekiResponsive.isMobile(context);
    final currentIndex = widget.navigationShell.currentIndex;

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
          gradient: const LinearGradient(
            colors: [YekiColors.textDark, Color(0xFF1A3A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: YekiShadowsExtension.shadowStrong,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = currentIndex == i;

            return GestureDetector(
              onTap: () => widget.navigationShell.goBranch(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? (isMobile ? 16 : 20) : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? YekiColors.primaryDark.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: YekiRadius.radiusLg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.$1 : item.$2,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? YekiColors.accent
                            : YekiColors.white.withValues(alpha: 0.54),
                        size: isSelected ? (isMobile ? 22 : 24) : (isMobile ? 20 : 22),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: isSelected
                          ? Padding(
                              padding: EdgeInsets.only(left: isMobile ? 6 : 8),
                              child: Text(
                                item.$3,
                                style: TextStyle(
                                  color: YekiColors.accent,
                                  fontSize: isMobile ? 11 : 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
