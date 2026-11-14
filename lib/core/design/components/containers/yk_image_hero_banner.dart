// lib/core/design/components/containers/yk_image_hero_banner.dart
//
// Bannière héro image + dégradé — même recette déjà utilisée par
// `concours_detail_page.dart::_buildHero` (image réelle du département +
// `LinearGradient([Colors.transparent, Colors.black54])` pour la
// lisibilité du texte en overlay), extraite ici pour être réutilisée par
// des en-têtes de page qui n'ont pas de département précis derrière eux
// (ex. les listes Formations/Prépa Concours, une seule bannière pour
// TOUTE la liste, pas par carte).
//
// `imageAssetPath` est chargée avec `Image.asset` de façon défensive
// (`errorBuilder`) : tant que le fichier n'existe pas réellement sur
// disque (ou n'est pas déclaré dans `pubspec.yaml`), un dégradé de repli
// `primary700→primary500` s'affiche à la place — jamais d'erreur, jamais
// d'écran cassé. Voir docs/ecarts (ou le rapport de ticket) pour la
// procédure d'ajout d'une vraie photo.

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../data/yk_badge.dart';

class YkImageHeroBanner extends StatelessWidget {
  const YkImageHeroBanner({
    super.key,
    required this.imageAssetPath,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    this.height = 180,
  });

  /// Chemin de l'asset attendu (ex. `assets/images/header_formations.jpg`)
  /// — n'a pas besoin d'exister pour que ce composant fonctionne (repli
  /// automatique sur le dégradé de marque).
  final String imageAssetPath;
  final String badgeLabel;
  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(YkRadius.lg),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [YkColors.primary700, YkColors.primary500],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: YkSpacing.md,
              right: YkSpacing.md,
              bottom: YkSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  YkBadge(variant: YkBadgeVariant.label, label: badgeLabel, color: Colors.white),
                  SizedBox(height: YkSpacing.xs),
                  Text(
                    title,
                    style: YkTypography.h3(context).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: YkSpacing.xxs),
                  Text(subtitle, style: YkTypography.bodySm(context).copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
