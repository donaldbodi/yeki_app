import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Thème Material construit DEPUIS les tokens — CDC_DESIGN §2/§3.7.
///
/// Remplace `YekiTheme` de `lib/core/theme/app_theme.dart` (supprimé) —
/// `theme:`/`darkTheme:` de `main.dart` pointent désormais ici. Les 13
/// sous-thèmes ci-dessous (boutons/inputs/cards/dialogs/etc.) sont un
/// port CONSCIENT de ceux de l'ancien fichier, pas une copie à
/// l'identique : les couleurs viennent de `YkColors` (ex. `primary700`
/// `#1A5276`, la couleur institutionnelle CDC) là où l'ancien fichier
/// utilisait des valeurs ad hoc jamais alignées sur cette couleur
/// officielle (ex. `#135F74`). Objet : rendre ce thème visuellement
/// ÉQUIVALENT à l'ancien pour les écrans qui dépendent encore du thème
/// hérité (`AppBar`/`PopupMenuButton`/`TabBar` non enveloppés dans leur
/// composant `Yk*`, ~30 fichiers recensés) sans avoir à les toucher un
/// par un — leur migration vers `YkAppBar`/`YkMenu`/`YkTabs` reste un
/// ticket séparé, non traité ici.
class YekiTheme {
  YekiTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: YkColors.primary700,
      onPrimary: YkColors.textOnPrimary,
      secondary: YkColors.primary500,
      onSecondary: YkColors.textOnPrimary,
      error: YkColors.error,
      onError: YkColors.textOnPrimary,
      surface: YkColors.surfaceLight,
      onSurface: YkColors.textPrimaryLight,
      surfaceContainerHighest: YkColors.surfaceVariantLight,
      onSurfaceVariant: YkColors.textSecondaryLight,
      outline: YkColors.borderLight,
    );
    return _themeFrom(
      colorScheme: colorScheme,
      background: YkColors.backgroundLight,
      textPrimary: YkColors.textPrimaryLight,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      // CDC §3.7 : en sombre, la primaire est primary300, PAS primary700
      // (1,6:1 de contraste sur le fond sombre contre 8,84:1 pour
      // primary300).
      primary: YkColors.primary300,
      onPrimary: YkColors.primary900,
      secondary: YkColors.primary300,
      onSecondary: YkColors.primary900,
      error: YkColors.error,
      onError: YkColors.textOnPrimary,
      surface: YkColors.surfaceDark,
      onSurface: YkColors.textPrimaryDark,
      surfaceContainerHighest: YkColors.surfaceVariantDark,
      onSurfaceVariant: YkColors.textSecondaryDark,
      outline: YkColors.borderDark,
    );
    return _themeFrom(
      colorScheme: colorScheme,
      background: YkColors.backgroundDark,
      textPrimary: YkColors.textPrimaryDark,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _themeFrom({
    required ColorScheme colorScheme,
    required Color background,
    required Color textPrimary,
    required Brightness brightness,
  }) {
    final textSecondary = colorScheme.onSurfaceVariant;
    final buttonRadius = BorderRadius.circular(YkRadius.sm);
    const titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    const buttonTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Plus Jakarta Sans',
      dividerColor: colorScheme.outline,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: 'Plus Jakarta Sans',
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleStyle.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: buttonTextStyle,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: buttonTextStyle,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: buttonTextStyle,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YkRadius.sm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: EdgeInsets.all(YkSpacing.md),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        hintStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
        errorStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.error),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary, height: 1.4),
        contentTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: textPrimary),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: colorScheme.primary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),

      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1, space: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outline,
      ),

      listTileTheme: ListTileThemeData(contentPadding: EdgeInsets.all(YkSpacing.md), dense: true),

      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.md)),
        elevation: 4,
      ),
    );
  }

  /// Bornage du facteur d'échelle système (`textScaler`) entre ×0,85 et
  /// ×1,60 — CDC_DESIGN §3.4 : au-delà, les mises en page à contrainte
  /// forte (tableaux de classement, grilles de dashboard) cassent. Fait
  /// une seule fois ici, dans le thème, pas écran par écran — branché sur
  /// `MaterialApp.router(builder:)`.
  static Widget clampedBuilder(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    final clampedScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.60,
    );
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedScaler),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
