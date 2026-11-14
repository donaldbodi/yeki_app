import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../nav/yk_nav_destination.dart';
import '../../tokens/tokens.dart';
import '../feedback/yk_snack.dart';
import 'yk_app_bar.dart';

/// Le composant pivot de toute la navigation — CDC_DESIGN §4.2.
///
/// UN SEUL composant sert les DEUX interfaces (Apprenant et Enseignant) ;
/// la seule différence entre les rôles vit dans `destinations`
/// (`YkNavConfig.forRole(role)`), jamais dans ce composant.
///
/// Décide seul de la forme de la navigation aux 5 ruptures
/// (`YkBreakpoints`) : barre du bas (compact) → rail replié 72 px
/// (medium/expanded, extensible au survol) → navbar déployée 280 px
/// (large) → navbar + panneau contextuel 320 px (xlarge).
class YkAdaptiveScaffold extends StatefulWidget {
  const YkAdaptiveScaffold({
    super.key,
    required this.groups,
    required this.selectedRouteName,
    required this.onDestinationTap,
    required this.body,
    this.contextPanel,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    required this.onSettings,
    required this.onLogout,
    this.badges = const {},
    this.compactAppBar,
  });

  /// En-tête affiché uniquement en `compact` (téléphone), par exemple
  /// `YkBrandAppBar` ; les autres tailles gardent leur navigation latérale.
  final PreferredSizeWidget? compactAppBar;

  /// `YkNavConfig.forRole(role)`.
  final List<YkNavGroup> groups;

  /// Route active — sert à surligner la bonne destination.
  final String? selectedRouteName;

  /// Appelé UNIQUEMENT pour une destination câblée (`routeName` non nul).
  /// Pour les autres, le composant affiche lui-même « Bientôt
  /// disponible » sans jamais appeler ce callback (voir P4.6 — environ
  /// la moitié des destinations du CDC n'ont pas encore d'écran).
  final ValueChanged<String> onDestinationTap;

  final Widget body;

  /// Affiché uniquement en `xlarge`, et seulement s'il est fourni.
  final Widget? contextPanel;

  final String userName;
  final String userRole;
  final String? avatarUrl;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  /// `{badgeKey: valeur}` — la config de navigation ne porte que la CLÉ
  /// (`YkNavDestination.badgeKey`), jamais la valeur : c'est l'écran
  /// appelant qui la fournit ici, recalculée à chaque rendu depuis ses
  /// propres providers.
  final Map<String, int> badges;

  @override
  State<YkAdaptiveScaffold> createState() => _YkAdaptiveScaffoldState();
}

class _YkAdaptiveScaffoldState extends State<YkAdaptiveScaffold> {
  bool _railExpanded = false;

  List<YkNavDestination> get _flat => [
    for (final group in widget.groups) ...group.destinations,
  ];

  int? _badgeFor(YkNavDestination d) => d.badgeKey == null ? null : widget.badges[d.badgeKey];

  bool _isSelected(YkNavDestination d) =>
      d.routeName != null && d.routeName == widget.selectedRouteName;

  void _handleTap(YkNavDestination d, BuildContext context) {
    if (!d.isWired) {
      YkSnack.info(context, 'Bientôt disponible');
      return;
    }
    widget.onDestinationTap(d.routeName!);
  }

  @override
  Widget build(BuildContext context) {
    switch (YkBreakpoints.of(context)) {
      case YkBreakpoint.compact:
        return _buildCompact(context);
      case YkBreakpoint.medium:
        return _buildRail(context, showAppBar: false);
      case YkBreakpoint.expanded:
        return _buildRail(context, showAppBar: true);
      case YkBreakpoint.large:
        return _buildWideNav(context, showContextPanel: false);
      case YkBreakpoint.xlarge:
        return _buildWideNav(context, showContextPanel: true);
    }
  }

  // ── compact — barre du bas ─────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final compactDestinations = _flat.where((d) => d.inCompactBar).toList();
    return Scaffold(
      // `extendBody: true` : le contenu défile SOUS la barre flottante
      // (maquette — barre en pilule, flottante, effet de verre) plutôt que
      // de s'arrêter au-dessus d'une barre pleine largeur opaque —
      // nécessaire pour que le flou de `_YkBottomBar` ait un contenu réel
      // à flouter derrière elle.
      extendBody: true,
      appBar: widget.compactAppBar,
      body: widget.body,
      bottomNavigationBar: _YkBottomBar(
        destinations: compactDestinations,
        isSelected: _isSelected,
        badgeFor: _badgeFor,
        onTap: (d) => _handleTap(d, context),
        onMore: () => _openOverflowSheet(context),
      ),
    );
  }

  Future<void> _openOverflowSheet(BuildContext context) {
    final compactLabels = _flat.where((d) => d.inCompactBar).map((d) => d.label).toSet();
    final rest = widget.groups
        .map(
          (g) => YkNavGroup(
            title: g.title,
            destinations: g.destinations.where((d) => !compactLabels.contains(d.label)).toList(),
          ),
        )
        .where((g) => g.destinations.isNotEmpty)
        .toList();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(YkSpacing.md),
          children: [
            _UserHeader(
              userName: widget.userName,
              userRole: widget.userRole,
              avatarUrl: widget.avatarUrl,
            ),
            SizedBox(height: YkSpacing.md),
            for (final group in rest) ...[
              if (group.title != null) _GroupTitle(title: group.title!),
              for (final d in group.destinations)
                _NavListTile(
                  destination: d,
                  selected: _isSelected(d),
                  badge: _badgeFor(d),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleTap(d, context);
                  },
                ),
              SizedBox(height: YkSpacing.sm),
            ],
            const Divider(),
            _NavListTile(
              destination: const YkNavDestination(label: 'Paramètres', icon: Icons.settings_outlined),
              selected: false,
              badge: null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onSettings();
              },
            ),
            _NavListTile(
              destination: const YkNavDestination(label: 'Déconnexion', icon: Icons.logout),
              selected: false,
              badge: null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── medium / expanded — rail replié, extensible au survol ──────────

  Widget _buildRail(BuildContext context, {required bool showAppBar}) {
    final flat = _flat;
    final selIdx = flat.indexWhere(_isSelected);

    final rail = MouseRegion(
      onEnter: (_) => setState(() => _railExpanded = true),
      onExit: (_) => setState(() => _railExpanded = false),
      child: NavigationRail(
        extended: _railExpanded,
        minWidth: 72,
        minExtendedWidth: 240,
        backgroundColor: YkColors.surface(context),
        selectedIndex: selIdx >= 0 ? selIdx : 0,
        onDestinationSelected: (i) => _handleTap(flat[i], context),
        destinations: [
          for (final d in flat)
            NavigationRailDestination(
              icon: _railIcon(context, d, selected: false),
              selectedIcon: _railIcon(context, d, selected: true),
              label: Text(d.label),
            ),
        ],
      ),
    );

    final content = Row(
      children: [
        rail,
        VerticalDivider(width: 1, color: YkColors.border(context)),
        Expanded(child: widget.body),
      ],
    );

    return Scaffold(
      appBar: showAppBar ? YkAppBar(title: widget.userRole) : null,
      body: content,
    );
  }

  Widget _railIcon(BuildContext context, YkNavDestination d, {required bool selected}) {
    final count = _badgeFor(d);
    final icon = Icon(selected ? (d.selectedIcon ?? d.icon) : d.icon);
    final badged = (count != null && count > 0)
        ? Badge(label: Text('$count'), child: icon)
        : icon;
    return Tooltip(
      message: d.isWired ? d.label : '${d.label} — bientôt disponible',
      child: Opacity(opacity: d.isWired ? 1 : 0.5, child: badged),
    );
  }

  // ── large / xlarge — navbar déployée 280px (+ panneau 320px) ───────

  Widget _buildWideNav(BuildContext context, {required bool showContextPanel}) {
    final panel = showContextPanel ? widget.contextPanel : null;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Container(
              color: YkColors.surface(context),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(YkSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Yéki',
                        style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm),
                      children: [
                        for (final group in widget.groups) ...[
                          if (group.title != null) _GroupTitle(title: group.title!),
                          for (final d in group.destinations)
                            _NavListTile(
                              destination: d,
                              selected: _isSelected(d),
                              badge: _badgeFor(d),
                              onTap: () => _handleTap(d, context),
                            ),
                          SizedBox(height: YkSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(YkSpacing.sm),
                    child: _UserFooter(
                      userName: widget.userName,
                      userRole: widget.userRole,
                      avatarUrl: widget.avatarUrl,
                      onSettings: widget.onSettings,
                      onLogout: widget.onLogout,
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: YkColors.border(context)),
          Expanded(child: widget.body),
          if (panel != null) ...[
            VerticalDivider(width: 1, color: YkColors.border(context)),
            SizedBox(width: 320, child: panel),
          ],
        ],
      ),
    );
  }
}

// ── Sous-widgets privés ───────────────────────────────────────────────

class _YkBottomBar extends StatelessWidget implements PreferredSizeWidget {
  const _YkBottomBar({
    required this.destinations,
    required this.isSelected,
    required this.badgeFor,
    required this.onTap,
    required this.onMore,
  });

  final List<YkNavDestination> destinations;
  final bool Function(YkNavDestination) isSelected;
  final int? Function(YkNavDestination) badgeFor;
  final ValueChanged<YkNavDestination> onTap;
  final VoidCallback onMore;

  @override
  Size get preferredSize => const Size.fromHeight(64 + 2 * 12 + 12);

  @override
  Widget build(BuildContext context) {
    // Barre flottante en pilule, effet de verre (maquette) — même recette
    // de flou que `YkCard(variant: glass)` (sigma 16, surface à 60 %
    // d'opacité, bordure à 30 %, ombre `e2`) : pas de nouvelle valeur
    // inventée, réutilisation directe.
    final radius = BorderRadius.circular(YkRadius.xl);
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: YkSpacing.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: YkColors.surface(context).withValues(alpha: 0.6),
                borderRadius: radius,
                border: Border.all(color: YkColors.surface(context).withValues(alpha: 0.3)),
                boxShadow: YkElevation.e2,
              ),
              child: Row(
                children: [
                  for (final d in destinations)
                    Expanded(child: _BottomBarItem(destination: d, selected: isSelected(d), badge: badgeFor(d), onTap: () => onTap(d))),
                  Expanded(
                    child: _BottomBarItem(
                      destination: const YkNavDestination(label: 'Plus', icon: Icons.more_horiz),
                      selected: false,
                      badge: null,
                      onTap: onMore,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final YkNavDestination destination;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YkColors.accent(context) : YkColors.textSecondary(context);
    final icon = Icon(selected ? (destination.selectedIcon ?? destination.icon) : destination.icon, color: color, size: 22);
    final badged = (badge != null && badge! > 0) ? Badge(label: Text('$badge'), child: icon) : icon;

    // Bug corrigé (conforme à la maquette) : le fond coloré de l'onglet
    // sélectionné n'enveloppe QUE l'icône (pastille pilule) — le libellé
    // reste un texte simple sans fond, coloré seulement.
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: YkMotion.fast,
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
                decoration: BoxDecoration(
                  color: selected ? YkColors.accent(context).withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(YkRadius.full),
                ),
                child: badged,
              ),
              SizedBox(height: 2),
              Text(
                destination.label,
                style: YkTypography.caption(context).copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(YkSpacing.sm, YkSpacing.md, YkSpacing.sm, YkSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: YkTypography.overline(context).copyWith(color: YkColors.textSecondary(context)),
      ),
    );
  }
}

class _NavListTile extends StatelessWidget {
  const _NavListTile({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final YkNavDestination destination;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YkColors.accent(context) : YkColors.textPrimary(context);
    return Semantics(
      button: true,
      selected: selected,
      label: destination.isWired ? destination.label : '${destination.label} — bientôt disponible',
      child: Material(
        color: selected ? YkColors.accent(context).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(YkRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          onTap: onTap,
          child: Opacity(
            opacity: destination.isWired ? 1 : 0.5,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.sm),
              child: Row(
                children: [
                  Icon(selected ? (destination.selectedIcon ?? destination.icon) : destination.icon, color: color, size: 20),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: YkTypography.bodyMd(context).copyWith(color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null && badge! > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: YkColors.error,
                        borderRadius: BorderRadius.circular(YkRadius.full),
                      ),
                      child: Text(
                        '$badge',
                        style: YkTypography.caption(context).copyWith(color: YkColors.textOnPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.userName, required this.userRole, this.avatarUrl});

  final String userName;
  final String userRole;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(userName: userName, avatarUrl: avatarUrl),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                userRole,
                style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    required this.onSettings,
    required this.onLogout,
  });

  final String userName;
  final String userRole;
  final String? avatarUrl;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
          child: _UserHeader(userName: userName, userRole: userRole, avatarUrl: avatarUrl),
        ),
        _NavListTile(
          destination: const YkNavDestination(label: 'Paramètres', icon: Icons.settings_outlined),
          selected: false,
          badge: null,
          onTap: onSettings,
        ),
        _NavListTile(
          destination: const YkNavDestination(label: 'Déconnexion', icon: Icons.logout),
          selected: false,
          badge: null,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.userName, this.avatarUrl});

  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl!));
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: YkColors.accent(context).withValues(alpha: 0.15),
      child: Text(initial, style: TextStyle(color: YkColors.accent(context), fontWeight: FontWeight.w700)),
    );
  }
}
