import 'package:flutter/painting.dart';

import 'colors.dart';

/// Élévation — CDC_DESIGN §3.5.
///
/// Ombres douces, jamais noires : la couleur d'ombre est [YkColors.primary900]
/// à faible opacité, ce qui donne une ombre teintée qui « appartient » à la
/// palette.
class YkElevation {
  YkElevation._();

  /// À plat (fond) — aucune ombre.
  static const List<BoxShadow> e0 = [];

  /// Carte au repos.
  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color(0x0F0B2C41), // primary900 @ 6%
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Carte survolée, barre d'app.
  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x140B2C41), // primary900 @ 8%
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Bottom sheet, menu.
  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x1A0B2C41), // primary900 @ 10%
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// Dialog modal, FAB étendu.
  static const List<BoxShadow> e4 = [
    BoxShadow(
      color: Color(0x1F0B2C41), // primary900 @ 12%
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
  ];
}
