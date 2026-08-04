import 'package:flutter/widgets.dart';

/// Échelle typographique fluide — CDC_DESIGN §3.4.
///
/// La taille interpole linéairement entre la valeur mobile (à 360 px de
/// largeur ou moins) et la valeur desktop (à 1240 px ou plus, début de la
/// rupture `large`). Aucune page ne déclare de [TextStyle] : elle appelle
/// un token.
class YkTypography {
  YkTypography._();

  static const double _mobileWidth = 360;
  static const double _desktopWidth = 1240;

  static double fluidSize(double width, double mobile, double desktop) {
    if (width <= _mobileWidth) return mobile;
    if (width >= _desktopWidth) return desktop;
    final t = (width - _mobileWidth) / (_desktopWidth - _mobileWidth);
    return mobile + (desktop - mobile) * t;
  }

  static TextStyle _fluidStyle({
    required double width,
    required double mobile,
    required double desktop,
    required FontWeight weight,
    required double height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: fluidSize(width, mobile, desktop),
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Écran d'accueil, splash, hero.
  static TextStyle display(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 32,
    desktop: 44,
    weight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -1,
  );

  /// Titre d'écran.
  static TextStyle h1(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 26,
    desktop: 34,
    weight: FontWeight.w800,
    height: 1.20,
    letterSpacing: -0.6,
  );

  /// Titre de section.
  static TextStyle h2(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 22,
    desktop: 27,
    weight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.3,
  );

  /// Titre de carte.
  static TextStyle h3(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 19,
    desktop: 22,
    weight: FontWeight.w700,
    height: 1.30,
  );

  /// Sous-titre.
  static TextStyle h4(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 17,
    desktop: 19,
    weight: FontWeight.w700,
    height: 1.35,
  );

  /// Corps de leçon, lecture longue.
  static TextStyle bodyLg(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 16,
    desktop: 17,
    weight: FontWeight.w400,
    height: 1.55,
  );

  /// Corps courant.
  static TextStyle bodyMd(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 14,
    desktop: 15,
    weight: FontWeight.w400,
    height: 1.50,
  );

  /// Texte secondaire.
  static TextStyle bodySm(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 13,
    desktop: 13,
    weight: FontWeight.w400,
    height: 1.45,
  );

  /// Libellé de bouton, onglet.
  static TextStyle label(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 14,
    desktop: 14,
    weight: FontWeight.w700,
    height: 1.20,
  );

  /// Légende, horodatage, méta.
  static TextStyle caption(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 12,
    desktop: 12,
    weight: FontWeight.w700,
    height: 1.35,
  );

  /// Étiquette de catégorie (majuscules).
  static TextStyle overline(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 11,
    desktop: 11,
    weight: FontWeight.w700,
    height: 1.20,
    letterSpacing: 0.8,
  );

  /// Code, référence de transaction, ID.
  static TextStyle mono(BuildContext context) => _fluidStyle(
    width: MediaQuery.sizeOf(context).width,
    mobile: 13,
    desktop: 14,
    weight: FontWeight.w400,
    height: 1.50,
  );
}
