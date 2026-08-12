// lib/core/design/components/ads/yk_adsense_banner.dart
//
// Switch conditionnel standard Flutter Web : `dart:html` n'est
// disponible qu'en compilation Web — bascule automatiquement vers la
// vraie implémentation (`yk_adsense_banner_web.dart`) sur le Web, et
// vers le stub inerte (`yk_adsense_banner_stub.dart`) sur toute autre
// plateforme, sans jamais faire fuiter d'API Web dans un build
// mobile/desktop natif.

export 'yk_adsense_banner_stub.dart' if (dart.library.html) 'yk_adsense_banner_web.dart';
