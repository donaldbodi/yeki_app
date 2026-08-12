// lib/services/adsense_config.dart
//
// Configuration Google AdSense (publicité mode gratuit — Web uniquement,
// voir `yk_ad_banner.dart`). Contrairement à AdMob, AdSense n'a AUCUN
// identifiant de test officiel documenté par Google — les 2 constantes
// ci-dessous restent VIDES tant qu'un vrai compte AdSense n'existe pas
// (règle 3 : jamais un identifiant inventé). Tant qu'elles sont vides,
// `YkAdBanner` n'affiche rien sur le Web (comportement identique à
// aujourd'hui, sans jamais tenter d'initialiser AdMob par erreur).
//
// Voir docs/ADSENSE_SETUP.md pour la procédure complète (création du
// compte, vérification du site, création d'un bloc d'annonce) — action
// externe qu'il reste à faire, comme pour le compte AdMob réel
// (docs/ADMOB_SETUP.md).

/// Identifiant éditeur AdSense (`ca-pub-XXXXXXXXXXXXXXXX`), relevé dans
/// la console AdSense une fois le compte créé et le site vérifié.
const String kAdSensePublisherId = '';

/// Identifiant du bloc d'annonce display créé dans la console AdSense.
const String kAdSenseSlotId = '';

/// Vrai seulement une fois les 2 constantes ci-dessus renseignées.
bool get kAdSenseConfigured => kAdSensePublisherId.isNotEmpty && kAdSenseSlotId.isNotEmpty;
