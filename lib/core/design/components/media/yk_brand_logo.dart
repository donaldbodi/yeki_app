// lib/core/design/components/media/yk_brand_logo.dart
//
// Logo YEKI : l'icône d'origine dans son disque bleu
// (`assets/images/yeki_logo_disque.png`), suivie si demandé du nom « Yéki »
// dans la police du logo. Utilisé par l'en-tête, le démarrage, l'onboarding
// et l'inscription, pour que la marque soit identique partout.

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class YkBrandLogo extends StatelessWidget {
  const YkBrandLogo({
    super.key,
    this.size = 32,
    this.showName = true,
    this.nameColor,
    this.nameSize,
  });

  /// Diamètre du disque.
  final double size;
  final bool showName;

  /// Couleur du nom ; par défaut l'accent du thème.
  final Color? nameColor;

  /// Taille du nom ; par défaut proportionnelle au disque.
  final double? nameSize;

  static const String asset = 'assets/images/yeki_logo_disque.png';

  @override
  Widget build(BuildContext context) {
    final disque = Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: showName ? null : 'Yéki',
    );
    if (!showName) return disque;
    return Semantics(
      label: 'Yéki',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          disque,
          SizedBox(width: size * 0.3),
          Text(
            'Yéki',
            style: YkTypography.brand(
              size: nameSize ?? size * 0.84,
              color: nameColor ?? YkColors.accent(context),
            ),
          ),
        ],
      ),
    );
  }
}
