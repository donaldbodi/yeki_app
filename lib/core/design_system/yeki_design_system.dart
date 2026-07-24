// lib/core/design_system/yeki_design_system.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YÉKI DESIGN SYSTEM — v2 (refonte complète)
//  ─────────────────────────────────────────────────────────────────────────
//  Ce fichier REMPLACE intégralement :
//    - core/theme/yeki_design_system.dart      (ancien)
//    - core/theme/yeki_design_extension.dart   (ancien)
//    - core/design_system/yeki_glass_kit.dart  (première itération)
//  → Supprimer ces 3 fichiers et remplacer tous leurs imports par :
//        import 'package:yeki/core/design_system/yeki_design_system.dart';
//
//  Principes directeurs :
//    1. Une seule couleur institutionnelle fixe (#1a5276) + une base neutre
//       adaptative (clair/sombre).
//    2. La couleur d'un cours n'est JAMAIS calculée dans l'app : elle est
//       choisie côté backend (palette officielle, voir COURSE_COLOR_PALETTE
//       ci-dessous, qui DOIT rester strictement synchronisée avec
//       COURSE_COLOR_PALETTE défini côté Django) et transmise via
//       `cours.colorCode`. `YekiCourseScope` se contente de la propager.
//    3. Grille 8dp stricte pour tous les espacements.
//    4. Trois niveaux d'élévation "verre" (glass1/2/3) qui remplacent les
//       ombres plates classiques par une vraie hiérarchie de profondeur.
//    5. Composants centralisés, appelés partout, jamais réécrits en dur
//       dans une page.
// ═══════════════════════════════════════════════════════════════════════════
// DÉPRÉCIÉ (P4.1) : remplacé par lib/core/design/tokens/ + lib/core/design/
// theme/yeki_theme.dart. Conservé actif tant que les écrans n'ont pas migré
// (voir CDC_DESIGN §2, phase 4 — aucun écran métier touché avant migration).
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. COULEURS — palette institutionnelle + neutres adaptatifs
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiColors {
  YekiColors._();

  /// Couleur principale générale de l'application (Bleu Profond Institutionnel).
  static const Color primary = Color(0xFF1A5276);
  static const Color primaryLight = Color(0xFF2E7DA6);
  static const Color primaryDark = Color(0xFF0F3B57);

  // Neutres — mode clair
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textFaint = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutres — mode sombre
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF16213A);
  static const Color textOnDark = Color(0xFFF1F5F9);
  static const Color textOnDarkMedium = Color(0xFFA3B0C2);
  static const Color borderDark = Color(0xFF2A3A55);

  // Sémantiques
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
  static const Color gold = Color(0xFFCA8A04);

  // ── Alias de compatibilité (anciennes pages utilisant app_theme.dart) ──
  // Permettent de migrer une page en ne changeant QUE sa ligne d'import.
  static const Color white = Colors.white;
  static const Color backgroundLight = bgLight;
  static const Color textLight = textFaint;
  static const Color purple = Color(0xFF9333EA);
  static const Color accent = Color(0xFF10B981);
}

/// Palette officielle des couleurs de cours — DOIT rester identique, dans
/// le même ordre, à `COURSE_COLOR_PALETTE` défini dans models.py (Django).
/// Utilisée uniquement pour l'affichage du picker côté enseignant ; l'app
/// apprenant ne fait que lire `cours.colorCode` renvoyé par l'API.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCourseSwatch {
  final String code;
  final String nom;
  const YekiCourseSwatch(this.code, this.nom);
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCoursePalette {
  YekiCoursePalette._();

  static const List<YekiCourseSwatch> official = [
    YekiCourseSwatch('#7C3AED', 'Violet Électrique'),
    YekiCourseSwatch('#10B981', 'Émeraude'),
    YekiCourseSwatch('#EA580C', 'Orange Brûlé'),
    YekiCourseSwatch('#DB2777', 'Rose Fuchsia'),
    YekiCourseSwatch('#2563EB', 'Bleu Roi'),
    YekiCourseSwatch('#CA8A04', 'Or Ambré'),
    YekiCourseSwatch('#0D9488', 'Sarcelle'),
    YekiCourseSwatch('#DC2626', 'Rouge Corail'),
    YekiCourseSwatch('#9333EA', 'Pourpre'),
    YekiCourseSwatch('#059669', 'Vert Jade'),
    YekiCourseSwatch('#EC4899', 'Magenta'),
    YekiCourseSwatch('#0284C7', 'Cyan Profond'),
  ];
}

/// Convertit un code hexadécimal ("#RRGGBB" ou "RRGGBB") renvoyé par l'API
/// en [Color]. Retombe sur [YekiColors.primary] si la valeur est invalide.
Color yekiColorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return YekiColors.primary;
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed != null ? Color(parsed) : YekiColors.primary;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. PROPAGATION DE LA COULEUR DE COURS
// ═══════════════════════════════════════════════════════════════════════════

/// Enroule toute la page de détail d'un cours pour propager sa couleur
/// (reçue depuis l'API, jamais calculée localement) à tous les composants
/// du design system : `YekiCourseScope(color: yekiColorFromHex(cours.colorCode), child: ...)`.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCourseScope extends InheritedWidget {
  final Color color;

  const YekiCourseScope({super.key, required this.color, required super.child});

  static Color of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YekiCourseScope>();
    return scope?.color ?? YekiColors.primary;
  }

  @override
  bool updateShouldNotify(YekiCourseScope oldWidget) => oldWidget.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. GRILLE 8DP, BREAKPOINTS & RESPONSIVE
// ═══════════════════════════════════════════════════════════════════════════

/// Unité de base (8dp). Toujours multiplier ce nombre plutôt que d'écrire
/// une valeur en dur : `YekiSpace.x3` au lieu de `24.0`.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiSpace {
  YekiSpace._();
  static const double x1 = 8;
  static const double x2 = 16;
  static const double x3 = 24;
  static const double x4 = 32;
  static const double x5 = 40;
  static const double x6 = 48;
  static const double half = 4;
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiRadius {
  YekiRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));

  // ── Alias de compatibilité (anciennes pages utilisant app_theme.dart) ──
  static const BorderRadius borderRadiusSm = rSm;
  static const BorderRadius borderRadiusMd = rMd;
  static const BorderRadius borderRadiusLg = rLg;
  static const BorderRadius borderRadiusXl = rXl;
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(40));
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiMotion {
  YekiMotion._();
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiResponsive {
  YekiResponsive._();
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext c) => MediaQuery.sizeOf(c).width <= mobileMax;
  static bool isTablet(BuildContext c) =>
      MediaQuery.sizeOf(c).width > mobileMax && MediaQuery.sizeOf(c).width <= tabletMax;
  static bool isDesktop(BuildContext c) => MediaQuery.sizeOf(c).width > tabletMax;

  static double pagePadding(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w > tabletMax) return YekiSpace.x4;
    if (w > mobileMax) return YekiSpace.x3;
    return YekiSpace.x2;
  }

  static double maxContentWidth(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w > tabletMax) return 1120;
    if (w > mobileMax) return 680;
    return double.infinity;
  }

  /// Nombre de colonnes de grille recommandé pour la largeur d'écran donnée.
  static int gridColumns(double width, {int desktop = 4}) {
    if (width > tabletMax) return desktop;
    if (width > mobileMax) return 2;
    return 1;
  }
}

/// Bascule mobile / tablette / desktop pour les layouts de page entière
/// (Cursus, Dashboards...). Sur tablette/desktop, insère naturellement une
/// NavigationRail à la place d'une BottomBar (voir YekiAppShell plus bas).
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const YekiResponsiveLayout({super.key, required this.mobile, this.tablet, required this.desktop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth > YekiResponsive.tabletMax) return desktop;
      if (c.maxWidth > YekiResponsive.mobileMax) return tablet ?? desktop;
      return mobile;
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. TYPOGRAPHIE — échelle responsive (le "nombre magique" 8)
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiType {
  YekiType._();

  /// Police d'expression (titres, hero) — géométrique, forte présence.
  // P3.5 : "Outfit" n'est ni demandée par le ticket ni déclarée en asset
  // local ; cette classe `YekiType` n'a par ailleurs aucun appelant nulle
  // part dans le projet (code mort, confirmé par grep) — repli sur "Plus
  // Jakarta Sans" (seule police ajoutée) le temps qu'une vraie police
  // d'expression soit tranchée et fournie en asset, sans impact visible
  // aujourd'hui.
  static TextStyle _display(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: 'Plus Jakarta Sans', fontSize: size, fontWeight: w, color: c,
      letterSpacing: -0.5, height: 1.15);

  /// Police utilitaire (corps de texte, UI) — grande lisibilité.
  static TextStyle _body(double size, FontWeight w, Color c, {double? height}) => TextStyle(
      fontFamily: 'Plus Jakarta Sans', fontSize: size, fontWeight: w, color: c,
      height: height ?? 1.45);

  static TextStyle hero(BuildContext ctx, {Color color = YekiColors.textDark}) =>
      _display(YekiResponsive.isMobile(ctx) ? 24 : 32, FontWeight.w900, color);

  static TextStyle title(BuildContext ctx, {Color color = YekiColors.textDark}) =>
      _display(YekiResponsive.isMobile(ctx) ? 16 : 20, FontWeight.w700, color);

  static TextStyle subtitle(BuildContext ctx, {Color color = YekiColors.textMedium}) =>
      _body(YekiResponsive.isMobile(ctx) ? 13 : 15, FontWeight.w600, color);

  static TextStyle body(BuildContext ctx, {Color color = YekiColors.textMedium}) =>
      _body(YekiResponsive.isMobile(ctx) ? 14 : 16, FontWeight.w500, color);

  static TextStyle caption({Color color = YekiColors.textFaint}) =>
      _body(12, FontWeight.w600, color, height: 1.3);

  static TextStyle badge({Color color = Colors.white}) =>
      _body(11, FontWeight.w700, color, height: 1.0);

  static TextStyle button({Color color = Colors.white}) =>
      _body(15, FontWeight.w700, color, height: 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. SURFACE VERRE — 3 niveaux d'élévation cohérents
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
enum YekiGlassTier {
  /// Surface discrète : listes, lignes secondaires.
  tier1,
  /// Surface standard : cartes, champs de saisie.
  tier2,
  /// Surface flottante prononcée : navbars, modales, boutons premium.
  tier3,
}

class _GlassSpec {
  final double opacity;
  final double blur;
  final double borderOpacity;
  final double borderWidth;
  final List<BoxShadow> shadow;
  const _GlassSpec(this.opacity, this.blur, this.borderOpacity, this.borderWidth, this.shadow);
}

_GlassSpec _specFor(YekiGlassTier tier, bool dark) {
  switch (tier) {
    case YekiGlassTier.tier1:
      return _GlassSpec(dark ? 0.55 : 0.65, 10, 0.15, 0.5, [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
      ]);
    case YekiGlassTier.tier2:
      return _GlassSpec(dark ? 0.65 : 0.75, 18, 0.2, 1.0, [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 22, offset: const Offset(0, 8)),
      ]);
    case YekiGlassTier.tier3:
      return _GlassSpec(dark ? 0.78 : 0.85, 28, 0.28, 1.4, [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 34, offset: const Offset(0, 14)),
      ]);
  }
}

/// Conteneur verre universel — remplace tous les anciens "GlassCard" épars.
/// C'est la brique de base de toute surface flottante de l'app.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiGlassSurface extends StatelessWidget {
  final Widget child;
  final YekiGlassTier tier;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;

  const YekiGlassSurface({
    super.key,
    required this.child,
    this.tier = YekiGlassTier.tier2,
    this.radius = YekiRadius.rLg,
    this.padding,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final spec = _specFor(tier, dark);
    final base = tintColor ?? (dark ? YekiColors.surfaceDark : YekiColors.surfaceLight);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: spec.blur, sigmaY: spec.blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: base.withValues(alpha: spec.opacity),
            borderRadius: radius,
            border: Border.all(
              color: (dark ? Colors.white : Colors.white).withValues(alpha: spec.borderOpacity),
              width: spec.borderWidth,
            ),
            boxShadow: spec.shadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. CARTE UNIVERSELLE + COLLECTION RESPONSIVE
// ═══════════════════════════════════════════════════════════════════════════

/// Carte cliquable standard pour Cours / Formations / Prépa Concours / Devoirs.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? accent;

  const YekiCard({super.key, required this.child, this.onTap, this.padding, this.accent});

  @override
  State<YekiCard> createState() => _YekiCardState();
}

class _YekiCardState extends State<YekiCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: YekiMotion.fast,
        curve: YekiMotion.standard,
        child: YekiGlassSurface(
          tier: YekiGlassTier.tier2,
          padding: widget.padding ?? const EdgeInsets.all(YekiSpace.x2),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wrapper responsive universel : liste verticale sur mobile, grille 2
/// colonnes sur tablette, 3-4 colonnes sur desktop.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCardCollection extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double childAspectRatio;
  final int desktopColumns;

  const YekiCardCollection({
    super.key,
    required this.children,
    this.spacing = YekiSpace.x2,
    this.childAspectRatio = 0.82,
    this.desktopColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, c) {
      final columns = YekiResponsive.gridColumns(c.maxWidth, desktop: desktopColumns);
      if (columns == 1) {
        return Column(children: [
          for (final w in children) Padding(padding: EdgeInsets.only(bottom: spacing), child: w),
        ]);
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, i) => children[i],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. BOUTON VERRE PREMIUM
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
enum YekiButtonStyle { filled, glass, outline, text }

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final Color? color;
  final YekiButtonStyle style;

  const YekiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.color,
    this.style = YekiButtonStyle.filled,
  });

  @override
  State<YekiButton> createState() => _YekiButtonState();
}

class _YekiButtonState extends State<YekiButton> {
  double _scale = 1;
  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? YekiCourseScope.of(context);
    final fg = widget.style == YekiButtonStyle.filled ? Colors.white : accent;

    BoxDecoration deco;
    switch (widget.style) {
      case YekiButtonStyle.filled:
        deco = BoxDecoration(
          gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.85)]),
          borderRadius: YekiRadius.rMd,
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
        );
        break;
      case YekiButtonStyle.glass:
        deco = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: YekiRadius.rMd,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        );
        break;
      case YekiButtonStyle.outline:
        deco = BoxDecoration(
          borderRadius: YekiRadius.rMd,
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
        );
        break;
      case YekiButtonStyle.text:
        deco = const BoxDecoration();
        break;
    }

    return GestureDetector(
      onTapDown: (_) => _enabled ? setState(() => _scale = 0.95) : null,
      onTapUp: (_) => _enabled ? setState(() => _scale = 1) : null,
      onTapCancel: () => setState(() => _scale = 1),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _scale,
        duration: YekiMotion.fast,
        child: Opacity(
          opacity: _enabled ? 1 : 0.5,
          child: Container(
            height: 52,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: YekiSpace.x3),
            decoration: deco,
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else ...[
                  if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 8)],
                  Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: YekiType.button(color: fg))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. CHAMPS DE SAISIE
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const YekiInputField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<YekiInputField> createState() => _YekiInputFieldState();
}

class _YekiInputFieldState extends State<YekiInputField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = YekiCourseScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: YekiType.caption(color: YekiColors.textMedium)),
        ),
        AnimatedContainer(
          duration: YekiMotion.base,
          decoration: BoxDecoration(
            color: YekiColors.surfaceLight.withValues(alpha: 0.7),
            borderRadius: YekiRadius.rMd,
            border: Border.all(
              color: _focused ? accent : YekiColors.borderLight,
              width: _focused ? 1.6 : 1,
            ),
            boxShadow: _focused
                ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            style: YekiType.body(context, color: YekiColors.textDark),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: YekiColors.textFaint),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: _focused ? accent : YekiColors.textMedium)
                  : null,
              suffixIcon: widget.suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: YekiSpace.x2, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiLargeAreaField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final int minLines;
  final String? Function(String?)? validator;

  const YekiLargeAreaField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.minLines = 5,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => YekiInputField(
        controller: controller,
        label: label,
        hint: hint,
        maxLines: minLines,
        validator: validator,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// 9. SÉLECTEUR DE COULEUR DE COURS (usage : formulaire enseignant principal)
// ═══════════════════════════════════════════════════════════════════════════

/// Grille de swatches alimentée par la palette officielle. Ne propose QUE
/// les couleurs renvoyées par `GET /api/cours/palette-couleurs/` — passer
/// la liste récupérée depuis l'API en paramètre `swatches`.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiCourseColorPicker extends StatelessWidget {
  final List<YekiCourseSwatch> swatches;
  final String? selectedCode;
  final ValueChanged<String> onSelect;

  const YekiCourseColorPicker({
    super.key,
    required this.swatches,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: YekiSpace.x2,
      runSpacing: YekiSpace.x2,
      children: [
        for (final s in swatches)
          GestureDetector(
            onTap: () => onSelect(s.code),
            child: Tooltip(
              message: s.nom,
              child: AnimatedContainer(
                duration: YekiMotion.fast,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: yekiColorFromHex(s.code),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedCode == s.code ? YekiColors.textDark : Colors.white,
                    width: selectedCode == s.code ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: yekiColorFromHex(s.code).withValues(alpha: 0.4),
                      blurRadius: selectedCode == s.code ? 14 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: selectedCode == s.code
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 10. NAVIGATION — Navbar / BottomBar / NavigationRail
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiNavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const YekiNavDestination({required this.icon, required this.activeIcon, required this.label});
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiGlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<YekiNavDestination> destinations;

  const YekiGlassBottomBar({super.key, required this.currentIndex, required this.onTap, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final accent = YekiCourseScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(YekiSpace.x2, 0, YekiSpace.x2, YekiSpace.x2),
        child: YekiGlassSurface(
          tier: YekiGlassTier.tier3,
          radius: YekiRadius.rXl,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < destinations.length; i++)
                  _NavIcon(dest: destinations[i], selected: i == currentIndex, accent: accent, onTap: () => onTap(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sur tablette/desktop (>600px), remplace la BottomBar par un rail latéral
/// afin de maximiser l'espace vertical, conformément au cahier des charges.
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiNavigationRailGlass extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<YekiNavDestination> destinations;
  final Widget? header;

  const YekiNavigationRailGlass({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final accent = YekiCourseScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(YekiSpace.x2),
      child: YekiGlassSurface(
        tier: YekiGlassTier.tier3,
        radius: YekiRadius.rLg,
        padding: const EdgeInsets.symmetric(vertical: YekiSpace.x3, horizontal: YekiSpace.x1),
        child: Column(
          children: [
            if (header != null) ...[header!, const SizedBox(height: YekiSpace.x3)],
            for (int i = 0; i < destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: YekiSpace.half),
                child: _NavIcon(dest: destinations[i], selected: i == currentIndex, accent: accent, onTap: () => onTap(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final YekiNavDestination dest;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _NavIcon({required this.dest, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: YekiMotion.base,
        curve: YekiMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: YekiRadius.rMd,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(selected ? dest.activeIcon : dest.icon, color: selected ? accent : YekiColors.textMedium, size: 24),
          const SizedBox(height: 3),
          AnimatedOpacity(
            duration: YekiMotion.fast,
            opacity: selected ? 1 : 0,
            child: Text(dest.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 11. MODAL SHEET UNIVERSELLE
// ═══════════════════════════════════════════════════════════════════════════

Future<T?> showYekiModalSheet<T>({
  required BuildContext context,
  required Widget child,
  double? maxWidthDesktop,
}) {
  if (YekiResponsive.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalShell(fromBottom: true, child: child),
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: YekiMotion.base,
    pageBuilder: (ctx, a1, a2) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidthDesktop ?? 560),
        child: _ModalShell(fromBottom: false, child: child),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: YekiMotion.spring),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _ModalShell extends StatelessWidget {
  final Widget child;
  final bool fromBottom;
  const _ModalShell({required this.child, required this.fromBottom});

  @override
  Widget build(BuildContext context) {
    final radius = fromBottom
        ? const BorderRadius.vertical(top: Radius.circular(YekiRadius.xl))
        : YekiRadius.rXl;
    return Padding(
      padding: fromBottom ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: YekiSpace.x2),
      child: YekiGlassSurface(
        tier: YekiGlassTier.tier3,
        radius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (fromBottom)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(4))),
              ),
            Flexible(child: child),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 12. PETITS COMPOSANTS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiBadge extends StatelessWidget {
  final String label;
  final Color color;
  const YekiBadge({super.key, required this.label, this.color = YekiColors.info});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: YekiType.badge(color: color)),
      );
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;
  const YekiProgressBar({super.key, required this.value, this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? YekiCourseScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: accent.withValues(alpha: 0.15),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0, 1),
          child: Container(color: accent),
        ),
      ),
    );
  }
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final double size;
  final bool ringed;
  const YekiAvatar({super.key, this.imageUrl, required this.fallbackInitial, this.size = 44, this.ringed = false});

  @override
  Widget build(BuildContext context) {
    final accent = YekiCourseScope.of(context);
    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: accent.withValues(alpha: 0.15),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(fallbackInitial.toUpperCase(), style: TextStyle(color: accent, fontWeight: FontWeight.w800))
          : null,
    );
    if (!ringed) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2)),
      child: avatar,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 13. COUCHE DE COMPATIBILITÉ — pour migrer une page existante en ne
//     changeant QUE sa ligne d'import (plus besoin de réécrire chaque
//     widget page par page). Nouvelles pages : utiliser directement les
//     tokens de la section 1 (YekiColors.bgLight, textFaint, etc.).
//     Les alias de couleurs/rayons sont directement dans YekiColors et
//     YekiRadius plus haut (une extension Dart ne peut pas ajouter de
//     membre statique accessible via le nom de la classe d'origine).
// ═══════════════════════════════════════════════════════════════════════════

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiGradients {
  YekiGradients._();
  static const LinearGradient mainBackground = LinearGradient(
    colors: [YekiColors.bgLight, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiShadows {  YekiShadows._();
  static List<BoxShadow> subtle = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> medium = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}

/// Alias vers un loader cohérent avec le nouveau système (remplace
/// l'ancien `YekiLoader` de app_theme.dart, même usage : `YekiLoader()`).
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
class YekiLoader extends StatelessWidget {
  final double size;
  final Color? color;
  const YekiLoader({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color ?? YekiCourseScope.of(context)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// 14. THEME DATA — à brancher dans MaterialApp(theme: yekiLightTheme, ...)
// ═══════════════════════════════════════════════════════════════════════════

ThemeData yekiLightTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YekiColors.bgLight,
      colorScheme: ColorScheme.fromSeed(seedColor: YekiColors.primary, brightness: Brightness.light),
      textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(fontFamily: 'Plus Jakarta Sans'),
      splashFactory: NoSplash.splashFactory,
    );

ThemeData yekiDarkTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YekiColors.bgDark,
      colorScheme: ColorScheme.fromSeed(seedColor: YekiColors.primary, brightness: Brightness.dark),
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(fontFamily: 'Plus Jakarta Sans'),
      splashFactory: NoSplash.splashFactory,
    );
