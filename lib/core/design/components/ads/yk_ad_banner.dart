// lib/core/design/components/ads/yk_ad_banner.dart
//
// Dispatcheur de bannière publicitaire par plateforme — remplace l'usage
// direct de `YkBannerAd` (AdMob, Android/iOS uniquement) à son seul site
// d'appel réel (`detail_lecon_page.dart`). La logique métier de gating
// (Premium/évaluation en cours, throttle) reste entièrement au site
// d'appel via `AdsService.doitAfficherPub()`/`doitAfficherEntreLecons()`
// — ce composant ne décide QUE du widget technique à rendre :
// - Web            → `YkAdSenseBanner` (Google AdSense, inerte tant que
//                     les identifiants réels ne sont pas configurés).
// - Android/iOS    → `YkBannerAd` (AdMob, inchangé).
// - Desktop natif  → rien (aucun système de publicité disponible pour
//                     une app desktop native, ni AdMob ni AdSense).
//
// `YkBannerAd`/`AdsService` restent intégralement inchangés — ce fichier
// ajoute une brique à côté, aucun risque de régression mobile (règle 1).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'yk_adsense_banner.dart';
import 'yk_banner_ad.dart';

class YkAdBanner extends StatelessWidget {
  const YkAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const YkAdSenseBanner();
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return const YkBannerAd();
    }
    return const SizedBox.shrink();
  }
}
