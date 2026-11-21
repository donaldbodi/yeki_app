// Vérifie la refonte P9.3 de l'écran de paiement unifié (remplace
// lib/views/pages/apprenants/paiement_page.dart) : rendu sans exception,
// YkPaywall pour l'accès département (mensuel + annuel si fourni +
// présentiel en complément séparé), recap simple pour les autres types.
//
// Le chargement réel (`PaiementRepository.parametresPublics`) tente un
// vrai appel réseau en test — aucune infrastructure de mock ApiClient/dio
// dans ce projet (même limite documentée pour
// classement_olympiade_page_test.dart) : l'échec est toléré.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/paiement/presentation/paiement_page.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(theme: ThemeData(brightness: brightness), home: child);
}

void main() {
  group('PaiementPage — types simples (pas de paywall)', () {
    testWidgets('se rend sans exception, clair et sombre (olympiade)', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(
            const PaiementPage(
              type: PaiementType.olympiade,
              olympiadeId: 1,
              titre: 'Grand Prix Yéki',
              montant: 100,
            ),
            brightness: brightness,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('ne plante pas si le réseau échoue (bascule sur un état géré)', (tester) async {
      await tester.pumpWidget(
        _host(
          const PaiementPage(type: PaiementType.rechargeWallet, titre: 'Recharge portefeuille', montant: 2000),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('PaiementPage — accesDepartement (YkPaywall)', () {
    testWidgets('se rend sans exception avec paywall + annuel + présentiel', (tester) async {
      await tester.pumpWidget(
        _host(
          const PaiementPage(
            type: PaiementType.accesDepartement,
            departementId: 5,
            titre: 'Terminale C',
            montant: 1500,
            montantAnnuel: 13000,
            montantPresentiel: 3000,
            isFormation: true,
            badge: 'Promotion',
            ancienPrixMensuel: 2000,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
