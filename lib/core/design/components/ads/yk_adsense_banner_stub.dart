// lib/core/design/components/ads/yk_adsense_banner_stub.dart
//
// Implémentation de repli (toute plateforme SAUF Web) du switch
// conditionnel `yk_adsense_banner.dart` — AdSense est un produit Web
// uniquement, jamais construit sur mobile/desktop natif. Ne devrait
// jamais être réellement monté (YkAdBanner ne l'utilise que sous
// `kIsWeb`), mais doit exister et compiler pour que le fichier commun
// reste valide sur toutes les plateformes.

import 'package:flutter/material.dart';

class YkAdSenseBanner extends StatelessWidget {
  const YkAdSenseBanner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
