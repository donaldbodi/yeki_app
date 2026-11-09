// lib/core/design/components/containers/yk_brand_app_bar.dart
//
// En-tête principal des espaces apprenant et enseignant, inspiré de
// WhatsApp : le nom « Yéki » seul à gauche, dans la police arrondie du logo
// (Fredoka), et les actions rangées à droite (action propre à l'écran,
// notifications, puis l'avatar). L'avatar ouvre un menu qui reprend le nom
// et le rôle de l'utilisateur : aucune information de l'ancien en-tête
// n'est perdue.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/tokens.dart';
import '../data/yk_avatar.dart';

/// Bouton d'action affiché à droite du nom, avant l'avatar.
class YkBrandAppBarAction {
  const YkBrandAppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Compteur affiché en pastille rouge (masqué à 0).
  final int badge;
}

class YkBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const YkBrandAppBar({
    super.key,
    this.actions = const [],
    required this.userName,
    required this.roleLabel,
    this.roleColor,
    this.avatarUrl,
    required this.onProfile,
    this.onSettings,
    required this.onLogout,
  });

  final List<YkBrandAppBarAction> actions;
  final String userName;
  final String roleLabel;

  /// Couleur du liseré de l'avatar et de la pastille de rôle ; à défaut,
  /// liseré clair et pastille aux couleurs de l'accent.
  final Color? roleColor;
  final String? avatarUrl;
  final VoidCallback onProfile;
  final VoidCallback? onSettings;
  final VoidCallback onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dark = YkColors.isDark(context);
    final fond = dark ? YkColors.surface(context) : YkColors.primary700;
    final texte = dark ? YkColors.textPrimary(context) : YkColors.textOnPrimary;
    final marque = dark ? YkColors.primary300 : YkColors.textOnPrimary;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: fond,
      foregroundColor: texte,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: dark ? Border(bottom: BorderSide(color: YkColors.border(context))) : null,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      titleSpacing: 18,
      title: Semantics(
        header: true,
        label: 'Yéki',
        child: Text(
          'Yéki',
          style: TextStyle(
            fontFamily: 'FredokaOne',
            fontSize: 27,
            height: 1,
            letterSpacing: 0.3,
            color: marque,
          ),
        ),
      ),
      actions: [
        for (final action in actions)
          IconButton(
            tooltip: action.tooltip,
            onPressed: action.onPressed,
            icon: Badge(
              isLabelVisible: action.badge > 0,
              label: Text(action.badge > 99 ? '99+' : '${action.badge}'),
              backgroundColor: YkColors.error,
              textColor: YkColors.textOnPrimary,
              child: Icon(action.icon, color: texte),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 10),
          child: _MenuAvatar(
            userName: userName,
            roleLabel: roleLabel,
            roleColor: roleColor,
            avatarUrl: avatarUrl,
            lisere: roleColor ?? (dark ? YkColors.primary300 : YkColors.textOnPrimary),
            onProfile: onProfile,
            onSettings: onSettings,
            onLogout: onLogout,
          ),
        ),
      ],
    );
  }
}

enum _Choix { profil, parametres, deconnexion }

class _MenuAvatar extends StatelessWidget {
  const _MenuAvatar({
    required this.userName,
    required this.roleLabel,
    required this.roleColor,
    required this.avatarUrl,
    required this.lisere,
    required this.onProfile,
    required this.onSettings,
    required this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final Color? roleColor;
  final String? avatarUrl;
  final Color lisere;
  final VoidCallback onProfile;
  final VoidCallback? onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final secondaire = YkColors.textSecondary(context);
    return PopupMenuButton<_Choix>(
      tooltip: 'Mon compte',
      offset: const Offset(0, kToolbarHeight - 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.md)),
      color: YkColors.surface(context),
      onSelected: (choix) {
        switch (choix) {
          case _Choix.profil:
            onProfile();
          case _Choix.parametres:
            onSettings?.call();
          case _Choix.deconnexion:
            onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_Choix>(
          enabled: false,
          child: Row(
            children: [
              YkAvatar(imageUrl: avatarUrl, fallbackText: userName, size: YkAvatarSize.sm),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    const SizedBox(height: 3),
                    YkRoleChip(label: roleLabel, color: roleColor ?? YkColors.accent(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_Choix>(
          value: _Choix.profil,
          child: _LigneMenu(icon: Icons.person_outline_rounded, label: 'Mon profil', color: secondaire),
        ),
        if (onSettings != null)
          PopupMenuItem<_Choix>(
            value: _Choix.parametres,
            child: _LigneMenu(icon: Icons.settings_outlined, label: 'Paramètres', color: secondaire),
          ),
        const PopupMenuItem<_Choix>(
          value: _Choix.deconnexion,
          child: _LigneMenu(icon: Icons.logout_rounded, label: 'Déconnexion', color: YkColors.error, danger: true),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: lisere, width: 2),
        ),
        child: YkAvatar(imageUrl: avatarUrl, fallbackText: userName, size: YkAvatarSize.sm),
      ),
    );
  }
}

class _LigneMenu extends StatelessWidget {
  const _LigneMenu({required this.icon, required this.label, required this.color, this.danger = false});

  final IconData icon;
  final String label;
  final Color color;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: YkTypography.bodyMd(context).copyWith(
            color: danger ? YkColors.error : YkColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

/// Pastille du rôle (« Cadre », « Apprenant »…). [onDark] : version claire,
/// lisible sur le bleu YEKI, avec un point de la couleur du rôle.
class YkRoleChip extends StatelessWidget {
  const YkRoleChip({super.key, required this.label, required this.color, this.onDark = false});

  final String label;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final texte = onDark ? YkColors.textOnPrimary : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? YkColors.textOnPrimary.withValues(alpha: 0.16) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(YkRadius.xl),
        border: Border.all(
          color: onDark ? YkColors.textOnPrimary.withValues(alpha: 0.28) : color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDark) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: YkTypography.caption(context).copyWith(color: texte, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
