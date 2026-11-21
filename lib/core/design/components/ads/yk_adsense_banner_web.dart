// lib/core/design/components/ads/yk_adsense_banner_web.dart
//
// Bannière Google AdSense — Web UNIQUEMENT (compilée seulement quand
// `dart:html` est disponible, voir le switch `yk_adsense_banner.dart`).
// Alternative réelle à AdMob (qui ne fonctionne pas sur le Web) pour la
// publicité en mode gratuit (CDC §8.3, étendu Web par décision explicite
// de l'utilisateur — le CDC ne prévoyait aucune alternative Web).
//
// Reste INERTE (rend `SizedBox.shrink()`) tant que `kAdSenseConfigured`
// est faux — voir `adsense_config.dart`/`docs/ADSENSE_SETUP.md` pour
// l'action externe restante (créer un compte AdSense réel, jamais
// inventé ici, règle 3).
//
// Mécanique : injecte un élément `<ins class="adsbygoogle">` via
// `HtmlElementView` (motif standard `dart:ui_web.platformViewRegistry`),
// charge le script officiel AdSense une seule fois par session, puis
// déclenche le remplissage de CET `<ins>` via
// `(window.adsbygoogle = window.adsbygoogle || []).push({})` — recette
// standard documentée par Google pour un rendu dynamique (Single Page
// App). Interop JS moderne (`package:web`/`dart:js_interop`, pas
// `dart:html`/`dart:js` dépréciés).

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../services/adsense_config.dart';

@JS('eval')
external void _jsEval(String code);

bool _scriptCharge = false;
int _compteurBannieres = 0;

void _chargerScriptAdSenseUneFois() {
  if (_scriptCharge) return;
  _scriptCharge = true;
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$kAdSensePublisherId'
    ..async = true
    ..crossOrigin = 'anonymous';
  web.document.head?.appendChild(script);
}

class YkAdSenseBanner extends StatefulWidget {
  const YkAdSenseBanner({super.key});

  @override
  State<YkAdSenseBanner> createState() => _YkAdSenseBannerState();
}

class _YkAdSenseBannerState extends State<YkAdSenseBanner> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    if (!kAdSenseConfigured) return;
    _chargerScriptAdSenseUneFois();
    _compteurBannieres++;
    _viewType = 'yeki-adsense-banner-$_compteurBannieres';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final ins = web.document.createElement('ins') as web.HTMLElement
        ..className = 'adsbygoogle'
        ..setAttribute('style', 'display:block')
        ..setAttribute('data-ad-client', kAdSensePublisherId)
        ..setAttribute('data-ad-slot', kAdSenseSlotId)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');
      // Déclenché après le montage réel du <ins> dans le DOM (Google
      // scanne les <ins class="adsbygoogle"> non encore remplis à
      // chaque push({})).
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _jsEval('(window.adsbygoogle = window.adsbygoogle || []).push({});');
        } catch (_) {
          // Script pas encore chargé / bloqueur de pub — silencieux,
          // même philosophie que YkBannerAd (jamais casser la mise en
          // page si l'annonce échoue à charger).
        }
      });
      return ins;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kAdSenseConfigured) return const SizedBox.shrink();
    return SizedBox(height: 90, width: double.infinity, child: HtmlElementView(viewType: _viewType));
  }
}
