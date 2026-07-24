import 'package:flutter/material.dart';

/// Halo décoratif — dégradé radial doux, purement visuel (ex. fond animé
/// de l'écran Splash). Couleur toujours fournie par l'appelant via un
/// token `YkColors`, jamais en dur.
class YkRadialGlow extends StatelessWidget {
  const YkRadialGlow({super.key, required this.color, this.alpha = 0.3, required this.size});

  final Color color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Anneau pulsé — la progression 0..1 d'un cycle de pulsation est fournie
/// par l'appelant (piloté par son propre `AnimationController`), ce
/// composant ne fait qu'en dessiner l'état à un instant donné. Utile pour
/// tout indicateur de chargement en forme d'anneau qui s'étend (ex. écran
/// Splash).
class YkPulseRing extends StatelessWidget {
  const YkPulseRing({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
    this.alpha = 0.45,
  });

  final double progress;
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final scale = 0.8 + progress * 0.9;
    final opacity = (1 - progress) * alpha;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 1.5),
        ),
      ),
    );
  }
}

/// Ombre douce diffuse derrière un élément (ex. logo sur fond sombre) —
/// enveloppe la seule utilisation autorisée de `BoxDecoration(boxShadow:)`
/// pour ce motif.
class YkGlowShadow extends StatelessWidget {
  const YkGlowShadow({
    super.key,
    required this.color,
    required this.child,
    this.blurRadius = 30,
    this.alpha = 0.5,
  });

  final Color color;
  final Widget child;
  final double blurRadius;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: alpha), blurRadius: blurRadius, offset: const Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}
