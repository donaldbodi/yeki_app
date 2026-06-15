// lib/core/theme/app_theme.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI DESIGN SYSTEM — CORRIGÉ (Flutter 3.22+)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. PALETTE DE COULEURS (UNIFIÉE)
// ═══════════════════════════════════════════════════════════════════════════

class YekiColors {
  static const Color primaryDark = Color(0xFF135F74);
  static const Color primaryLight = Color(0xFF2884A0);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color accent = Color(0xFFFF6B00);
  static const Color gold = Color(0xFFC5A059);
  static const Color purple = Color(0xFF8B5CF6);

  static const Color textDark = Color(0xFF1A1C1E);
  static const Color textMedium = Color(0xFF5A5C5E);
  static const Color textLight = Color(0xFF8A8C8E);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundAlt = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color borderLight = Color(0xFFE0E4E8);
  static const Color borderMedium = Color(0xFFD0D4D8);
  static const Color borderDark = Color(0xFFC0C4C8);
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. TYPOGRAPHIE
// ═══════════════════════════════════════════════════════════════════════════

class YekiTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w900, color: YekiColors.textDark,
    height: 1.2, letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w800, color: YekiColors.textDark,
    height: 1.3, letterSpacing: -0.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800, color: YekiColors.textDark,
    height: 1.3, letterSpacing: -0.2,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: YekiColors.textDark,
    height: 1.4, letterSpacing: -0.1,
  );
  static const TextStyle h5 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: YekiColors.textDark,
    height: 1.4,
  );
  static const TextStyle h6 = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, color: YekiColors.textDark,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, color: YekiColors.textDark,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: YekiColors.textDark,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: YekiColors.textMedium,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: YekiColors.textMedium,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, color: YekiColors.textLight,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: YekiColors.textLight,
    letterSpacing: 0.3,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800, color: YekiColors.textLight,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. OMBRES
// ═══════════════════════════════════════════════════════════════════════════

class YekiShadows {
  static List<BoxShadow> subtle = [
    BoxShadow(color: YekiColors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> medium = [
    BoxShadow(color: YekiColors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> strong = [
    BoxShadow(color: YekiColors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> primary = [
    BoxShadow(color: YekiColors.primaryDark.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> accent = [
    BoxShadow(color: YekiColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> floating = [
    BoxShadow(color: YekiColors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. RAYONS DE BORDURE
// ═══════════════════════════════════════════════════════════════════════════

class YekiRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
  
  static BorderRadius borderRadiusXs = BorderRadius.circular(xs);
  static BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
  static BorderRadius borderRadiusPill = BorderRadius.circular(pill);
  
  static BorderRadius borderRadiusTopLg = const BorderRadius.vertical(top: Radius.circular(lg));
  static BorderRadius borderRadiusBottomLg = const BorderRadius.vertical(bottom: Radius.circular(lg));
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. ESPACEMENTS
// ═══════════════════════════════════════════════════════════════════════════

class YekiSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 60;
  
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);
  
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);
  
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. ANIMATIONS
// ═══════════════════════════════════════════════════════════════════════════

class YekiDurations {
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
}

class YekiCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. THEME COMPLET (CORRIGÉ pour Flutter 3.22+)
// ═══════════════════════════════════════════════════════════════════════════

class YekiTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      primaryColor: YekiColors.primaryDark,
      colorScheme: const ColorScheme.light(
        primary: YekiColors.primaryDark,
        secondary: YekiColors.accent,
        tertiary: YekiColors.gold,
        error: YekiColors.error,
        surface: YekiColors.white,
      ),
      
      scaffoldBackgroundColor: YekiColors.backgroundLight,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: YekiColors.white,
        foregroundColor: YekiColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: YekiTextStyles.h6,
        iconTheme: IconThemeData(color: YekiColors.textDark),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YekiColors.primaryDark,
          foregroundColor: YekiColors.white,
          elevation: 0,
          padding: YekiSpacing.paddingMd,
          shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusMd),
          textStyle: YekiTextStyles.buttonMedium,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YekiColors.primaryDark,
          side: const BorderSide(color: YekiColors.borderLight),
          padding: YekiSpacing.paddingMd,
          shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusMd),
          textStyle: YekiTextStyles.buttonMedium,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: YekiColors.primaryDark,
          padding: YekiSpacing.paddingMd,
          shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusMd),
          textStyle: YekiTextStyles.buttonMedium,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YekiColors.white,
        border: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: const BorderSide(color: YekiColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: const BorderSide(color: YekiColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: const BorderSide(color: YekiColors.error),
        ),
        contentPadding: YekiSpacing.paddingLg,
        labelStyle: YekiTextStyles.labelMedium,
        hintStyle: YekiTextStyles.bodySmall,
        errorStyle: YekiTextStyles.caption.copyWith(color: YekiColors.error),
      ),
      
      // ✅ CORRIGÉ : CardThemeData au lieu de CardTheme
      cardTheme: const CardThemeData(
        color: YekiColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      
      // ✅ CORRIGÉ : DialogThemeData au lieu de DialogTheme
      dialogTheme: const DialogThemeData(
        backgroundColor: YekiColors.white,
        titleTextStyle: YekiTextStyles.h5,
        contentTextStyle: YekiTextStyles.bodyMedium,
      ),
      
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: YekiColors.textDark,
        contentTextStyle: TextStyle(color: YekiColors.white),
      ),
      
      // ✅ CORRIGÉ : TabBarThemeData au lieu de TabBarTheme
      tabBarTheme: const TabBarThemeData(
        labelColor: YekiColors.primaryDark,
        unselectedLabelColor: YekiColors.textLight,
        indicatorColor: YekiColors.primaryDark,
        labelStyle: YekiTextStyles.labelMedium,
        unselectedLabelStyle: YekiTextStyles.labelSmall,
      ),
      
      dividerTheme: const DividerThemeData(
        color: YekiColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: YekiColors.primaryDark,
        linearTrackColor: YekiColors.borderLight,
      ),
      
      listTileTheme: const ListTileThemeData(
        contentPadding: YekiSpacing.paddingLg,
        dense: true,
      ),
      
      popupMenuTheme: PopupMenuThemeData(
        color: YekiColors.white,
        shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusLg),
        elevation: 4,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════════════════

class YekiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const YekiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? YekiColors.primaryDark;
    final textColor = foregroundColor ?? YekiColors.white;
    
    return SizedBox(
      width: isExpanded ? double.infinity : width,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: padding ?? YekiSpacing.paddingLg,
          shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusMd),
          elevation: onPressed == null ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: YekiTextStyles.buttonMedium.copyWith(color: textColor)),
                ],
              ),
      ),
    );
  }
}

class YekiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;

  const YekiCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.shadow,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? YekiColors.white,
        borderRadius: borderRadius ?? YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight, width: 1),
        boxShadow: shadow ?? YekiShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? YekiRadius.borderRadiusLg,
          child: Padding(padding: padding ?? YekiSpacing.paddingLg, child: child),
        ),
      ),
    );
  }
}

class YekiBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isOutlined;

  const YekiBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YekiSpacing.sm, vertical: YekiSpacing.xs),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: YekiRadius.borderRadiusSm,
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: YekiTextStyles.labelSmall.copyWith(
            color: isOutlined ? color : color, fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}

class YekiSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  const YekiSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: YekiSpacing.paddingVerticalSm,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? YekiColors.primaryDark),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: YekiTextStyles.h5.copyWith(color: color))),
          if (trailing != null) trailing!,
        ],
      ),
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

class YekiSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const YekiSkeleton({super.key, required this.height, this.width, this.radius = YekiRadius.md});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: YekiColors.borderLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class YekiSpacer extends StatelessWidget {
  final double height;
  const YekiSpacer(this.height, {super.key});
  @override Widget build(BuildContext context) => SizedBox(height: height);
}

// Extension pour faciliter l'utilisation des couleurs
extension YekiColorExtension on Color {
  Color withOpacityValue(double opacity) {
    return withAlpha((opacity * 255).round().clamp(0, 255));
  }
}