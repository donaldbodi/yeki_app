import 'package:flutter/widgets.dart';

/// Vitesses de mouvement — CDC_DESIGN §3.6.
enum YkMotionSpeed {
  /// Retour tactile, changement d'état de bouton.
  instant,

  /// Survol, chip, checkbox.
  fast,

  /// Transition d'écran, ouverture de carte.
  normal,

  /// Bottom sheet, dialog.
  slow,

  /// Réussite d'exercice, gain de rang, badge.
  celebrate,
}

class YkMotion {
  YkMotion._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration celebrate = Duration(milliseconds: 700);

  static const Curve instantCurve = Curves.easeOut;
  static const Curve fastCurve = Curves.easeOutCubic;
  static const Curve normalCurve = Curves.easeInOutCubic;
  static const Curve slowCurve = Curves.easeInOutCubic;
  static const Curve celebrateCurve = Curves.elasticOut;

  static Duration _base(YkMotionSpeed speed) {
    switch (speed) {
      case YkMotionSpeed.instant:
        return instant;
      case YkMotionSpeed.fast:
        return fast;
      case YkMotionSpeed.normal:
        return normal;
      case YkMotionSpeed.slow:
        return slow;
      case YkMotionSpeed.celebrate:
        return celebrate;
    }
  }

  static Curve curveFor(YkMotionSpeed speed) {
    switch (speed) {
      case YkMotionSpeed.instant:
        return instantCurve;
      case YkMotionSpeed.fast:
        return fastCurve;
      case YkMotionSpeed.normal:
        return normalCurve;
      case YkMotionSpeed.slow:
        return slowCurve;
      case YkMotionSpeed.celebrate:
        return celebrateCurve;
    }
  }

  /// Respect obligatoire de `MediaQuery.disableAnimations` (préférence
  /// système « réduire les animations ») : lorsqu'elle est active, toutes
  /// les durées passent à [Duration.zero] sauf les transitions d'opacité.
  /// Bascule faite dans le token, une seule fois.
  static Duration duration(
    BuildContext context,
    YkMotionSpeed speed, {
    bool isOpacity = false,
  }) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced && !isOpacity) return Duration.zero;
    return _base(speed);
  }
}
