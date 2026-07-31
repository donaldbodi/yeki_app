import 'dart:ui' show Brightness;

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

/// Palette — CDC_DESIGN §3.2/§3.7.
///
/// Valeurs recopiées EXACTEMENT du document : elles ont été calculées et
/// leurs contrastes vérifiés, ne pas les « améliorer » à l'œil.
class YkColors {
  YkColors._();

  // Échelle primaire — teinte ancrée à 203,5°, primary700 = couleur imposée
  // #1A5276 (contraste 8,36:1 sur blanc, conforme WCAG AAA texte normal).
  static const primary50 = Color(0xFFEFF5F8);
  static const primary100 = Color(0xFFD8E7F0);
  static const primary200 = Color(0xFFB5D1E3);
  static const primary300 = Color(0xFF8AB8D6);
  static const primary400 = Color(0xFF589ECA);
  static const primary500 = Color(0xFF3081B5);
  static const primary600 = Color(0xFF236895);
  static const primary700 = Color(0xFF1A5276);
  static const primary800 = Color(0xFF123E5A);
  static const primary900 = Color(0xFF0B2C41);

  // Sémantique — alignées en saturation/luminance sur la primaire.
  // warning (3,36:1) et info (3,81:1) sont INTERDITS comme couleur de texte
  // sur fond blanc (sous 4,5:1) : utilisables en remplissage (icône,
  // bandeau, bordure) avec un texte en variante foncée. Cette règle est
  // encodée dans les composants Yk*, pas laissée à l'appréciation de
  // l'intégrateur.
  static const success = Color(0xFF278645);
  static const warning = Color(0xFFB8821E);
  static const error = Color(0xFFB6332B);
  static const info = Color(0xFF2F8CB1);

  // Neutres — légèrement teintés en 203,5° (un gris pur à côté d'un
  // bleu-pétrole paraît sale).
  static const neutral0 = Color(0xFFFCFDFD);
  static const neutral50 = Color(0xFFF8F9F9);
  static const neutral100 = Color(0xFFEFF1F3);
  static const neutral200 = Color(0xFFE0E5E8);
  static const neutral300 = Color(0xFFCCD2D7);
  static const neutral400 = Color(0xFFA0AAB1);
  static const neutral500 = Color(0xFF788791);
  static const neutral600 = Color(0xFF5C6B75);
  static const neutral700 = Color(0xFF46545D);
  static const neutral800 = Color(0xFF2D3941);
  static const neutral900 = Color(0xFF1D272D);
  static const neutral950 = Color(0xFF111A1F);

  // Rôles sémantiques — mode clair (mapping exact CDC §3.2.3).
  static const backgroundLight = neutral50;
  static const surfaceLight = neutral0;
  static const surfaceVariantLight = neutral100;
  static const borderLight = neutral200;
  static const textPrimaryLight = neutral900;
  static const textSecondaryLight = neutral600;
  static const textTertiaryLight = neutral400;
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Mode sombre (CDC §3.7) — primary EN SOMBRE = primary300, PAS primary700 :
  // #1A5276 sur #0C1317 ne donne que 1,6:1 de contraste (illisible), contre
  // 8,84:1 pour primary300 (#8AB8D6).
  static const backgroundDark = Color(0xFF0C1317);
  static const surfaceDark = Color(0xFF111A1F);
  static const surfaceVariantDark = Color(0xFF1D272D);
  static const borderDark = Color(0xFF2D3941);
  static const textPrimaryDark = Color(0xFFEFF1F3);
  static const textSecondaryDark = Color(0xFFA0AAB1);

  // ── Accesseurs contextuels clair/sombre ──────────────────────────────
  // Les composants Yk* lisent les couleurs via ces accesseurs plutôt que
  // via Theme.of(context).colorScheme — seul le signal clair/sombre vient
  // de Theme, les valeurs de couleur viennent toujours de ce token (P4.3).
  // `main.dart` utilise désormais `design/theme/yeki_theme.dart` (bascule
  // faite, `app_theme.dart` supprimé).
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceVariant(BuildContext context) =>
      isDark(context) ? surfaceVariantDark : surfaceVariantLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textTertiaryLight;

  /// Couleur d'accent primaire adaptée au thème (primary300 en sombre,
  /// voir §3.7 — jamais primary700 sur fond sombre, contraste insuffisant).
  static Color accent(BuildContext context) =>
      isDark(context) ? primary300 : primary700;

  /// Couleur de texte/icône lisible SUR [accent] (ex. libellé de bouton
  /// `primary`).
  static Color onAccent(BuildContext context) =>
      isDark(context) ? primary900 : textOnPrimary;

  // ── Splash (P5.1) ────────────────────────────────────────────────────
  // Identité visuelle propre à l'écran Splash (maquette, écran 19) — PAS
  // une rampe de surface sombre générique à réutiliser ailleurs : aucune
  // des 3 teintes ne correspond à l'échelle primary300..900 ci-dessus.
  static const _splashNavy1 = Color(0xFF0E2233);
  static const _splashNavy2 = Color(0xFF0F172A);
  static const _splashNavy3 = Color(0xFF0A1220);
  static const splashGradient = LinearGradient(
    begin: Alignment(0, -0.9),
    end: Alignment(0, 1),
    colors: [_splashNavy1, _splashNavy2, _splashNavy3],
    stops: [0, 0.55, 1],
  );

  // ── Onboarding (P5.2) ────────────────────────────────────────────────
  // Fond doux pour l'écran Onboarding — toujours clair (comme Splash est
  // toujours sombre), quel que soit le thème ambiant : un dégradé de
  // bienvenue est une identité visuelle fixe, pas une surface qui doit
  // s'adapter clair/sombre.
  static const onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary50, neutral0],
  );
}

/// Une couleur de cours : teinte de base, fond doux, et variante foncée
/// utilisée comme texte sur le fond doux.
class YkCourseSwatch {
  const YkCourseSwatch({
    required this.nom,
    required this.base,
    required this.soft,
    required this.deep,
  });

  final String nom;
  final Color base;
  final Color soft;
  final Color deep;
}

/// Les 12 couleurs de cours — CDC_DESIGN §3.3, règle métier, pas décoration.
///
/// « Les couleurs à générer pour les cours ne doivent pas directement être
/// insérées dans les pages Flutter en dur ; elles doivent servir aux
/// enseignants cadres qui créent les cours — ce sont eux qui choisissent la
/// couleur du cours lors de la création. »
///
/// Cette liste alimente UNIQUEMENT le sélecteur de couleur du formulaire de
/// création/modification de cours (`creer_cours_sheet.dart`,
/// `modifier_cours_sheet.dart`). Toute page qui affiche un cours lit sa
/// couleur depuis le champ `couleur` renvoyé par l'API, jamais depuis cette
/// palette, jamais en dur.
///
/// ATTENTION : diverge intentionnellement de `COURSE_COLOR_PALETTE`
/// (backend Django, `apps/formation/models.py`) et de
/// `YekiCoursePalette.official` (`design_system/yeki_design_system.dart`),
/// qui sont synchronisées entre elles mais PAS avec le CDC. Décision actée
/// P4.1 : ce token n'est PAS encore branché à un écran ni au backend
/// (Phase 4 ne touche aucun écran métier). Un futur ticket devra synchroniser
/// Django et migrer les feuilles de création/modification de cours vers
/// cette palette.
class YkCourseColors {
  YkCourseColors._();

  static const palette = <YkCourseSwatch>[
    YkCourseSwatch(
      nom: 'Azur',
      base: Color(0xFF2E7CAD),
      soft: Color(0xFFE7F2F8),
      deep: Color(0xFF19557B),
    ),
    YkCourseSwatch(
      nom: 'Bleu',
      base: Color(0xFF5F6BD4),
      soft: Color(0xFFE7E9F8),
      deep: Color(0xFF2839C4),
    ),
    YkCourseSwatch(
      nom: 'Indigo',
      base: Color(0xFF8A5CD4),
      soft: Color(0xFFEEE7F8),
      deep: Color(0xFF6327C0),
    ),
    YkCourseSwatch(
      nom: 'Violet',
      base: Color(0xFFBB39CB),
      soft: Color(0xFFF6E7F8),
      deep: Color(0xFF8F209D),
    ),
    YkCourseSwatch(
      nom: 'Magenta',
      base: Color(0xFFCB3B92),
      soft: Color(0xFFF8E7F2),
      deep: Color(0xFF9E206D),
    ),
    YkCourseSwatch(
      nom: 'Rose',
      base: Color(0xFFCD4453),
      soft: Color(0xFFF8E7E9),
      deep: Color(0xFFA82231),
    ),
    YkCourseSwatch(
      nom: 'Orange',
      base: Color(0xFFAE612E),
      soft: Color(0xFFF8EEE7),
      deep: Color(0xFF7C4019),
    ),
    YkCourseSwatch(
      nom: 'Ambre',
      base: Color(0xFF817622),
      soft: Color(0xFFF8F6E7),
      deep: Color(0xFF4C4510),
    ),
    YkCourseSwatch(
      nom: 'Lime',
      base: Color(0xFF5C8022),
      soft: Color(0xFFF2F8E7),
      deep: Color(0xFF344C0F),
    ),
    YkCourseSwatch(
      nom: 'Vert',
      base: Color(0xFF2E8624),
      soft: Color(0xFFE9F8E7),
      deep: Color(0xFF185211),
    ),
    YkCourseSwatch(
      nom: 'Émeraude',
      base: Color(0xFF23854A),
      soft: Color(0xFFE7F8EE),
      deep: Color(0xFF11512A),
    ),
    YkCourseSwatch(
      nom: 'Turquoise',
      base: Color(0xFF238278),
      soft: Color(0xFFE7F8F6),
      deep: Color(0xFF104E47),
    ),
  ];
}
