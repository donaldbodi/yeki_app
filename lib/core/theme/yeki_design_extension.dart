// lib/core/theme/yeki_design_extension.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI DESIGN SYSTEM EXTENSION — INTERFACES ENSEIGNANT
//  Ce fichier étend le design system existant sans le modifier
// ═══════════════════════════════════════════════════════════════════════════
// DÉPRÉCIÉ (P4.1) : remplacé par lib/core/design/tokens/ + lib/core/design/
// theme/yeki_theme.dart. Conservé actif tant que les écrans n'ont pas migré
// (voir CDC_DESIGN §2, phase 4 — aucun écran métier touché avant migration).

import 'package:flutter/material.dart';
import 'yeki_design_system.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. CONSTANTES DE COULEURS SUPPLÉMENTAIRES
// ═══════════════════════════════════════════════════════════════════════════

// ── Couleurs par type d'enseignant ──────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiRoleColors {
  static const Color admin = Color(0xFF7C3AED);      // Violet
  static const Color adminBg = Color(0xFFEDE9FE);
  static const Color cadre = Color(0xFF2884A0);      // Bleu (même que primary)
  static const Color cadreBg = Color(0xFFE0F2F1);
  static const Color principal = Color(0xFFE2A84B);  // Or (même que gold)
  static const Color principalBg = Color(0xFFFFF3E0);
  static const Color enseignant = Color(0xFF10B981); // Vert (même que success)
  static const Color enseignantBg = Color(0xFFECFDF5);
}

// ── Couleurs d'état supplémentaires ──────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiStateColors {
  static const Color pending = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2884A0);
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. GRADIENTS SUPPLÉMENTAIRES
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiGradientsExtension {
  static const LinearGradient gradientAdmin = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarning = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFE2A84B), Color(0xFFD48B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. OMBRES SUPPLÉMENTAIRES
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiShadowsExtension {
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowStrong = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. COMPOSANTS UI SUPPLÉMENTAIRES
// ═══════════════════════════════════════════════════════════════════════════

// ── Badge pour les rôles ──────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiRoleBadge extends StatelessWidget {
  final String role;
  final double? fontSize;

  const YekiRoleBadge({
    super.key,
    required this.role,
    this.fontSize,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
      case 'enseignant_admin':
        return YekiRoleColors.admin;
      case 'cadre':
      case 'enseignant_cadre':
        return YekiRoleColors.cadre;
      case 'principal':
      case 'enseignant_principal':
        return YekiRoleColors.principal;
      case 'enseignant':
        return YekiRoleColors.enseignant;
      default:
        return YekiColors.primary;
    }
  }

  Color _getRoleBg(String role) {
    switch (role) {
      case 'admin':
      case 'enseignant_admin':
        return YekiRoleColors.adminBg;
      case 'cadre':
      case 'enseignant_cadre':
        return YekiRoleColors.cadreBg;
      case 'principal':
      case 'enseignant_principal':
        return YekiRoleColors.principalBg;
      case 'enseignant':
        return YekiRoleColors.enseignantBg;
      default:
        return YekiColors.primary.withValues(alpha: 0.1);
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin Général';
      case 'enseignant_admin':
        return 'Admin';
      case 'cadre':
        return 'Cadre';
      case 'enseignant_cadre':
        return 'Cadre';
      case 'principal':
        return 'Principal';
      case 'enseignant_principal':
        return 'Principal';
      case 'enseignant':
        return 'Enseignant';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    final bg = _getRoleBg(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: YekiRadius.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        _getRoleLabel(role),
        style: TextStyle(
          color: color,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Card améliorée ──────────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;
  final Border? border;

  const YekiCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.shadow,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? YekiColors.white,
        borderRadius: borderRadius ?? YekiRadius.radiusLg,
        boxShadow: shadow ?? YekiShadowsExtension.shadowMedium,
        border: border ?? Border.all(color: YekiColors.borderLight, width: 1),
      ),
      padding: padding ?? EdgeInsets.all(YekiResponsive.dynamicPadding(context)),
      child: child,
    );
  }
}

// ── Section avec titre ──────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const YekiSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.iconColor,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? YekiColors.primary),
                const SizedBox(width: 8),
              ],
              Text(title, style: YekiTextStyles.h2(context)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const YekiStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? YekiColors.white,
        borderRadius: YekiRadius.radiusMd,
        border: Border.all(color: YekiColors.borderLight, width: 1),
        boxShadow: YekiShadowsExtension.shadowMedium,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: YekiRadius.radiusSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: YekiTextStyles.caption.copyWith(
              color: YekiColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Indicator ──────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiStatusIndicator extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const YekiStatusIndicator({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: YekiRadius.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final Color? backgroundColor;
  final double radius;
  final bool showBorder;

  const YekiAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.backgroundColor,
    this.radius = 20,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? YekiColors.primary.withValues(alpha: 0.1),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null && initials != null
          ? Text(
              initials!,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
                color: backgroundColor ?? YekiColors.primary,
              ),
            )
          : null,
    );
  }
}

// ── Navigation pour enseignant ──────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiEnseignantNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<YekiNavigationItem> items;

  const YekiEnseignantNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        border: Border(top: BorderSide(color: YekiColors.borderLight, width: 1)),
        boxShadow: YekiShadowsExtension.shadowMedium,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;
              
              return GestureDetector(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? YekiColors.primary : YekiColors.textLight,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? YekiColors.primary : YekiColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiNavigationItem {
  final String label;
  final IconData icon;
  final Widget page;

  const YekiNavigationItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

// ── Fonction utilitaire pour obtenir la couleur d'un rôle ──────────────────
Color _getRoleColor(String role) {
  switch (role) {
    case 'admin':
    case 'enseignant_admin':
      return YekiRoleColors.admin;
    case 'cadre':
    case 'enseignant_cadre':
      return YekiRoleColors.cadre;
    case 'principal':
    case 'enseignant_principal':
      return YekiRoleColors.principal;
    case 'enseignant':
      return YekiRoleColors.enseignant;
    default:
      return YekiColors.primary;
  }
}

String _getRoleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Administrateur Général';
    case 'enseignant_admin':
      return 'Enseignant Administrateur';
    case 'cadre':
      return 'Enseignant Cadre';
    case 'enseignant_cadre':
      return 'Enseignant Cadre';
    case 'principal':
      return 'Enseignant Principal';
    case 'enseignant_principal':
      return 'Enseignant Principal';
    case 'enseignant':
      return 'Enseignant';
    default:
      return 'Utilisateur';
  }
}

// ── Header pour les pages enseignant ──────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiEnseignantHeader extends StatelessWidget {
  final String nom;
  final String role;
  final Map<String, dynamic>? stats;

  const YekiEnseignantHeader({
    super.key,
    required this.nom,
    required this.role,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(role);
    final roleLabel = _getRoleLabel(role);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roleColor, roleColor.withValues(alpha: 0.85)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: YekiColors.white.withValues(alpha: 0.15),
                    borderRadius: YekiRadius.radiusLg,
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: const TextStyle(
                      color: YekiColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: YekiColors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: YekiColors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nom,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: YekiColors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenue sur votre espace',
              style: TextStyle(
                color: YekiColors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            if (stats != null && stats!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMiniStat('${stats!['nb_cours'] ?? 0}', 'Cours'),
                  const SizedBox(width: 24),
                  _buildMiniStat('${stats!['nb_apprenants'] ?? 0}', 'Apprenants'),
                  const SizedBox(width: 24),
                  _buildMiniStat('${stats!['taux_moyen'] ?? 0}%', 'Taux'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: YekiColors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style:  TextStyle(
            color: YekiColors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}