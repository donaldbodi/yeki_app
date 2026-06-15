// lib/core/theme/yeki_theme.dart
// ═══════════════════════════════════════════════════════════════════
//  YEKI DESIGN SYSTEM — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Tokens de couleur ────────────────────────────────────────────
class YColors {
  static const blue      = Color(0xFF2884A0);
  static const blueDark  = Color(0xFF1F6580);
  static const teal      = Color(0xFF2A657D);
  static const tealLight = Color(0xFF39A0C2);

  static const gold      = Color(0xFFE2A84B);
  static const coral     = Color(0xFFFF7F77);
  static const green     = Color(0xFF10B981);
  static const purple    = Color(0xFF8B5CF6);
  static const orange    = Color(0xFFF97316);

  static const dark      = Color(0xFF0D1B2A);
  static const darkMid   = Color(0xFF1E293B);
  static const grey      = Color(0xFF64748B);
  static const greyLight = Color(0xFFCBD5E1);
  static const bgLight   = Color(0xFFF8FAFC);
  static const bgMid     = Color(0xFFF1F5F9);
  static const white     = Color(0xFFFFFFFF);

  static const inkBg     = Color(0xFF0D1117);
  static const inkSurf   = Color(0xFF161B22);
  static const inkCard   = Color(0xFF1C2128);
  static const inkBorder = Color(0xFF30363D);
}

// ── Extension pour faciliter l'utilisation des couleurs ──────────
extension YColorsExtension on Color {
  /// Utilisation: color.withValues(alpha: 0.5)
  Color withValues({double? alpha}) {
    return withAlpha((alpha ?? 1.0 * 255).round().clamp(0, 255));
  }
  
  /// Version simplifiée pour la compatibilité
  Color opacity(double value) {
    return withValues(alpha: value);
  }
}

// ── Typographie ──────────────────────────────────────────────────
class YText {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: YColors.dark, height: 1.2);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YColors.dark, height: 1.3);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YColors.dark, height: 1.4);
  static const h4 = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: YColors.dark, height: 1.4);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: YColors.darkMid, height: 1.6);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: YColors.grey, height: 1.5);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: YColors.grey, height: 1.4);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: YColors.dark, height: 1.4);
}

// ── Ombres ───────────────────────────────────────────────────────
class YShadow {
  // ✅ CORRIGÉ : withValues(alpha: 0.07) au lieu de withValues(0.07)
  static List<BoxShadow> card = [
    BoxShadow(color: YColors.blue.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> float = [
    BoxShadow(color: YColors.dark.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> subtle = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

// ── Rayons ───────────────────────────────────────────────────────
class YRadius {
  static const sm  = 8.0;
  static const md  = 14.0;
  static const lg  = 20.0;
  static const xl  = 28.0;
  static const full = 100.0;
}

// ── Dégradés ────────────────────────────────────────────────────
class YGradient {
  static const primary = LinearGradient(
    colors: [YColors.blue, YColors.teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gold = LinearGradient(
    colors: [Color(0xFFE2A84B), Color(0xFFD4912E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const dark = LinearGradient(
    colors: [Color(0xFF1A3A4A), YColors.teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static LinearGradient fromColor(Color c) => LinearGradient(
    colors: [c, _darken(c, 0.15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static Color _darken(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amt).clamp(0.0, 1.0)).toColor();
  }
}

// ── Composants partagés ──────────────────────────────────────────

/// Bouton principal gradient
class YButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final Color? color;
  final double? width;
  final EdgeInsets? padding;

  const YButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.color,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final grad = color != null
        ? YGradient.fromColor(color!)
        : YGradient.primary;
    return Container(
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(YRadius.md),
        boxShadow: [
          BoxShadow(
            // ✅ CORRIGÉ : withValues(alpha: 0.3)
            color: (color ?? YColors.blue).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(YRadius.md),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de tag coloré
class YChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const YChip({super.key, required this.label, required this.color, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // ✅ CORRIGÉ : withValues(alpha: 0.12)
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(YRadius.full),
          // ✅ CORRIGÉ : withValues(alpha: 0.3)
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Carte standard avec ombre
class YCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? radius;

  const YCard({super.key, required this.child, this.padding, this.color, this.onTap, this.radius});

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(YRadius.lg);
    return Container(
      decoration: BoxDecoration(
        color: color ?? YColors.white,
        borderRadius: br,
        boxShadow: YShadow.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Avatar initiales ou photo
class YAvatar extends StatelessWidget {
  final String nom;
  final String? photoUrl;
  final double radius;
  final Color? color;
  final bool isTeacher;

  const YAvatar({
    super.key,
    required this.nom,
    this.photoUrl,
    this.radius = 20,
    this.color,
    this.isTeacher = false,
  });

  String get _initials {
    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? YColors.blue;
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          // ✅ CORRIGÉ : withValues(alpha: 0.15)
          backgroundColor: bg.withValues(alpha: 0.15),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Text(_initials, style: TextStyle(
                  fontSize: radius * 0.55,
                  fontWeight: FontWeight.w800,
                  color: bg,
                ))
              : null,
        ),
        if (isTeacher)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: const BoxDecoration(
                color: YColors.tealLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified, size: radius * 0.35, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

/// Indicateur de statut coloré
class YStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const YStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // ✅ CORRIGÉ : withValues(alpha: 0.12)
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(YRadius.full),
        // ✅ CORRIGÉ : withValues(alpha: 0.3)
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Header dégradé pour SliverAppBar
class YSliverHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final LinearGradient? gradient;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;

  const YSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.gradient,
    this.actions,
    this.leading,
    this.expandedHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: YColors.blue,
      leading: leading,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? YGradient.primary,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        )),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

/// Skeleton loader
class YSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const YSkeleton({super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<YSkeleton> createState() => _YSkeletonState();
}

class _YSkeletonState extends State<YSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFF8FAFC), _anim.value),
        ),
      ),
    );
  }
}