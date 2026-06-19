// lib/core/theme/yeki_design_system.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI UNIFIED RESPONSIVE DESIGN SYSTEM — GLASSMORPHISM EDITION
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';

/// ── 1. CONFIGURATION DES BREAKPOINTS & UTILS RESPONSIVE ──────────────────
class YekiResponsive {
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > mobileMax &&
      MediaQuery.sizeOf(context).width <= tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax;

  /// Calcule une taille adaptative selon la largeur de l'écran (Fluid Sizing)
  static double dynamicPadding(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    if (width > tabletMax) return 32.0;
    if (width > mobileMax) return 24.0;
    return 16.0;
  }

  /// Limite la largeur des conteneurs sur tablette/desktop pour préserver l'UX
  static double maxContentWidth(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    if (width > tabletMax) return 1100.0;
    if (width > mobileMax) return 650.0;
    return double.infinity;
  }
}

/// ── 2. LAYOUT RESPONSIVE GLOBAL ──────────────────────────────────────────
class YekiResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const YekiResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > YekiResponsive.tabletMax) {
          return desktop;
        }
        if (constraints.maxWidth > YekiResponsive.mobileMax) {
          return tablet ?? desktop; // Repli vers desktop si pas de tablette spécifique
        }
        return mobile;
      },
    );
  }
}

class YekiLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const YekiLoader({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color ?? YekiColors.primaryDark,
      ),
    );
  }
}


/// ── 3. PALETTE DE COULEURS UNIFIÉE ────────────────────────────────────────
class YekiColors {
  static const Color primary = Color(0xFF2884A0);
  static const Color purple    = Color.fromARGB(255, 218, 61, 108);
  static const Color primaryDark = Color(0xFF1F5F75);
  static const Color primaryLight = Color(0xFF39A0C2);
  
  static const Color accent = Color(0xFFFF7F77); 
  static const Color gold = Color(0xFFE2A84B);   
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFDA3D6C);

  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgLight = Color(0xFFF4F8FC);
  static const Color borderLight = Color(0xFFF4F8FC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMedium = Color(0xFF64748B);
  static const Color textLight = Color(0xFFCBD5E1);
  static const Color white = Colors.white;

  static Color glassBgLight = Colors.white.withAlpha(140);     
  static Color glassBorderLight = Colors.white.withAlpha(180); 
}

/// ── 4. GRADIENTS MULTI-COUCHES ───────────────────────────────────────────
class YekiGradients {
  static const LinearGradient mainBackground = LinearGradient(
    colors: [Color(0xFFE0F2F1), Color(0xFFF4F8FC), Color(0xFFE1BEE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassCard = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.50),
      Colors.white.withValues(alpha: 0.15),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ── 5. RAYONS DE COURBURE EN COHÉRENCE VIA LES BREAKPOINTS ───────────────
class YekiRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;

  static BorderRadius radiusSm = BorderRadius.circular(sm);
  static BorderRadius radiusMd = BorderRadius.circular(md);
  static BorderRadius radiusLg = BorderRadius.circular(lg);
}

/// ── 6. TYPOGRAPHIES FLUIDES ET ADAPTATIVES ────────────────────────────────
class YekiTextStyles {
  static TextStyle h1(BuildContext context) => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: YekiResponsive.isMobile(context) ? 24 : 36,
        fontWeight: FontWeight.w900,
        color: YekiColors.textDark,
        letterSpacing: -0.5,
      );

  static TextStyle h2(BuildContext context) => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: YekiResponsive.isMobile(context) ? 20 : 28,
        fontWeight: FontWeight.w800,
        color: YekiColors.textDark,
        letterSpacing: -0.3,
      );

  // CORRECTION : Transformation en méthode adaptative prenant le BuildContext
  static TextStyle h3(BuildContext context) => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: YekiResponsive.isMobile(context) ? 16 : 20,
        fontWeight: FontWeight.w700,
        color: YekiColors.textDark,
      );

  static TextStyle body(BuildContext context) => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: YekiResponsive.isMobile(context) ? 14 : 16,
        fontWeight: FontWeight.w500,
        color: YekiColors.textMedium,
        height: 1.4,
      );

  static const TextStyle caption = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: YekiColors.textMedium);
  static const TextStyle button = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5);
}

/// ── 7. CONTENEUR EN VERRE RESPONSIVE ──────────────────────────────────────
class YekiGlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const YekiGlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 20.0,
    this.borderWidth = 1.2,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? YekiRadius.radiusLg;
    final calculatedPadding = padding ?? EdgeInsets.all(YekiResponsive.dynamicPadding(context));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: calculatedPadding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: YekiGradients.glassCard,
            border: Border.all(
              color: YekiColors.glassBorderLight,
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ── 8. BOUTON RESPONSIVE UNIFIÉ ──────────────────────────────────────────
class YekiButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color color;
  final double? width;

  const YekiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.color = YekiColors.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: width ?? (YekiResponsive.isMobile(context) ? double.infinity : 280),
      decoration: BoxDecoration(
        borderRadius: YekiRadius.radiusMd,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: YekiRadius.radiusMd),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: YekiTextStyles.button),
                ],
              ),
      ),
    );
  }
}