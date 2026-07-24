import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Thème Material construit DEPUIS les tokens — CDC_DESIGN §2/§3.7.
///
/// Remplace, à terme, `YekiTheme` de `lib/core/theme/app_theme.dart` (qui
/// reste actif et marqué `@Deprecated` tant que les écrans n'ont pas migré
/// vers ces tokens — voir P4.1). Le `theme:`/`darkTheme:` réellement
/// appliqués dans `main.dart` restent ceux de l'ancien fichier jusqu'à la
/// fin de la migration écran par écran ; seul [clampedBuilder] est branché
/// dès maintenant, car le bornage du `textScaler` est une exigence
/// d'accessibilité globale, indépendante de la palette affichée.
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
