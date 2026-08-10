// lib/services/ads_service.dart
//
// Publicité AdMob — mode gratuit uniquement (CDC_BACKEND §8.3 : « il est
// question d'implémenter de manière complète et astucieuse la publicité
// dans Yéki pour le mode gratuit, c'est-à-dire sans abonnement, via
// Firebase »). `google_mobile_ads` était déjà dans `pubspec.yaml` mais
// totalement non câblé (confirmé par recherche exhaustive) — ce fichier
// est le point d'entrée UNIQUE (règle 1, aucune vue ne doit réimplémenter
// sa propre logique d'affichage publicitaire).
//
// Règles non négociables, citées textuellement par le CDC :
// - jamais pendant un exercice/devoir/olympiade en cours ;
// - jamais pour un utilisateur Premium (désormais : Premium DU
//   DÉPARTEMENT du contenu concerné, voir la refonte du modèle
//   économique) — [doitAfficherPub] exige un booléen explicite à chaque
//   appel, jamais deviné en interne (règle 3) ;
// - jamais au démarrage (avant le premier contenu) ;
// - contenu tout public (`MaxAdContentRating.g`) ;
// - `tagForChildDirectedTreatment`/`tagForUnderAgeOfConsent` selon la
//   date de naissance déclarée à l'inscription (`Profile.date_naissance`,
//   déjà collectée, jamais exploitée jusqu'ici).
//
// IDs d'app/de bloc : IDs DE TEST OFFICIELS GOOGLE (documentés,
// https://developers.google.com/admob/flutter/test-ads) — sûrs à
// committer, jamais suspendus. Voir docs/ADMOB_SETUP.md pour les 3
// actions externes restantes (compte AdMob réel, blocs d'annonces,
// remplacement de ces IDs) avant toute publication.

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  String get bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _testBannerIos : _testBannerAndroid;
  String get interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _testInterstitialIos : _testInterstitialAndroid;
  String get rewardedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _testRewardedIos : _testRewardedAndroid;

  // Throttling en mémoire process (remis à zéro au redémarrage) — suffisant
  // pour respecter "max 1 native / 5 leçons" et "max 1 interstitiel /
  // 10 min" à l'échelle d'une session ; pas besoin de persistance disque
  // pour ce type de garde-fou.
  int _leconsDepuisDerniereNative = 0;
  DateTime? _dernierInterstitiel;

  InterstitialAd? _interstitiel;
  RewardedAd? _rewarded;

  /// [dateNaissanceIso] optionnelle (`UserProfile.dateNaissance`,
  /// `"YYYY-MM-DD"`) — absente au premier appel (avant connexion), un 2ᵉ
  /// appel avec la vraie date une fois le profil chargé est sûr
  /// (idempotent, `updateRequestConfiguration` peut être rappelé).
  Future<void> init({String? dateNaissanceIso}) async {
    final estMineur = _estMineur(dateNaissanceIso);
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment:
            estMineur ? TagForChildDirectedTreatment.yes : TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent:
            estMineur ? TagForUnderAgeOfConsent.yes : TagForUnderAgeOfConsent.unspecified,
      ),
    );
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _precharger();
  }

  bool _estMineur(String? dateNaissanceIso) {
    // Ne jamais deviner (règle 3) : sans donnée, pas de sur-tag "mineur".
    if (dateNaissanceIso == null) return false;
    final naissance = DateTime.tryParse(dateNaissanceIso);
    if (naissance == null) return false;
    final age = DateTime.now().difference(naissance).inDays ~/ 365;
    return age < 18;
  }

  void _precharger() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitiel = ad,
        onAdFailedToLoad: (_) => _interstitiel = null,
      ),
    );
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Décision centrale, jamais devinée : l'appelant doit connaître avec
  /// certitude le statut Premium (DU DÉPARTEMENT du contenu affiché,
  /// rectification du modèle économique) et si une évaluation est en
  /// cours avant d'appeler quoi que ce soit d'autre sur ce service.
  bool doitAfficherPub({required bool estPremiumDeLaMatiere, bool evaluationEnCours = false}) {
    return !estPremiumDeLaMatiere && !evaluationEnCours;
  }

  /// Bannière adaptative — « bas de liste de cours/exercices » (CDC §8.3).
  BannerAd creerBanniere({
    required AdSize size,
    void Function(Ad ad)? onLoaded,
    void Function(Ad ad, LoadAdError error)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded?.call(ad),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call(ad, error);
        },
      ),
    )..load();
  }

  /// « Entre deux leçons du flux, max 1 native / 5 leçons » (CDC §8.3).
  /// Approximation assumée et documentée (pas un oubli) : un vrai template
  /// natif custom nécessiterait des vues platform-natives Android/iOS
  /// dédiées, un chantier disproportionné pour ce ticket — [creerBanniere]
  /// occupe le même emplacement avec le même throttle 1/5, voir
  /// docs/ADMOB_SETUP.md pour la piste d'un vrai native ad plus tard.
  bool doitAfficherEntreLecons() {
    _leconsDepuisDerniereNative++;
    if (_leconsDepuisDerniereNative >= 5) {
      _leconsDepuisDerniereNative = 0;
      return true;
    }
    return false;
  }

  /// « Après un résultat d'exercice, max 1 / 10 min, jamais avant
  /// l'affichage du résultat » (CDC §8.3) — l'appelant affiche d'abord le
  /// résultat, PUIS appelle ceci ; l'ordre n'est pas garanti ici.
  Future<void> afficherInterstitielApresResultat() async {
    final ad = _interstitiel;
    if (ad == null) return;
    final maintenant = DateTime.now();
    if (_dernierInterstitiel != null &&
        maintenant.difference(_dernierInterstitiel!) < const Duration(minutes: 10)) {
      return;
    }
    _dernierInterstitiel = maintenant;
    _interstitiel = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _precharger();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _precharger();
      },
    );
    await ad.show();
  }

  /// « Déblocage d'un indice Yéki IA, avec récompense — volontaire »
  /// (CDC §8.3). Exposée dès maintenant mais SANS appelant réel dans ce
  /// ticket : aucun mécanisme d'indice n'existe encore dans l'app
  /// (recherche exhaustive confirmée) — l'inventer serait une
  /// fonctionnalité fantôme (règle 3). À câbler le jour où cette
  /// fonctionnalité existera.
  Future<bool> afficherRecompenseePourIndice({required void Function(RewardItem recompense) onRecompense}) async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _precharger();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _precharger();
      },
    );
    var recompense = false;
    await ad.show(
      onUserEarnedReward: (_, reward) {
        recompense = true;
        onRecompense(reward);
      },
    );
    return recompense;
  }
}
