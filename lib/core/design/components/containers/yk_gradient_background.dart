import 'package:flutter/material.dart';

/// Fond en dégradé plein écran — seule utilisation autorisée de
/// `BoxDecoration(gradient:)` pour ce motif (règle 2 : zéro `BoxDecoration`
/// hors `lib/core/design/`). Le [gradient] vient toujours d'un token
/// (ex. `YkColors.splashGradient`), jamais construit en dur par l'appelant.
class YkGradientBackground extends StatelessWidget {
  const YkGradientBackground({super.key, required this.gradient, required this.child});

  final Gradient gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
