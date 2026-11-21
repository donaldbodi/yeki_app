// lib/core/design/components/ads/yk_banner_ad.dart
//
// Wrapper de cycle de vie pour une bannière AdMob (charge/affiche/dispose
// proprement) — voir `lib/services/ads_service.dart` pour la politique
// d'affichage (jamais Premium, jamais pendant une évaluation, CDC §8.3).
// Rendu vide (`SizedBox.shrink`) tant que l'annonce n'a pas chargé — ne
// réserve jamais un espace vide en attendant, ne casse jamais la mise en
// page si l'annonce échoue à charger (réseau, aucun inventaire).

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:yeki/services/ads_service.dart';

class YkBannerAd extends StatefulWidget {
  const YkBannerAd({super.key, this.size = AdSize.banner});

  final AdSize size;

  @override
  State<YkBannerAd> createState() => _YkBannerAdState();
}

class _YkBannerAdState extends State<YkBannerAd> {
  BannerAd? _ad;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _ad = AdsService.instance.creerBanniere(
      size: widget.size,
      onLoaded: (_) {
        if (mounted) setState(() => _charge = true);
      },
      onFailed: (_, _) {
        if (mounted) setState(() => _charge = false);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_charge || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
