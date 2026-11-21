// Vérifie la refonte P8.3 de l'écran « inscription à une olympiade ».
// Contrairement aux autres écrans du ticket, celui-ci ne fait AUCUN appel
// réseau à l'ouverture (toutes ses données viennent des paramètres de
// route) : les assertions ci-dessous sont donc synchrones, sans tolérance
// réseau à prévoir.
//
// Point clé du ticket : le bouton de paiement/inscription ne doit
// apparaître que si `prixParticipation > 0` — sinon l'inscription est
// gratuite et directe. Le paiement effectif (402 → YkManualPaymentFlow)
// est un flux serveur-driven, couvert par
// `olympiade_inscription_controller_test.dart` (le contrôleur laisse
// remonter l'ApiException 402 à l'écran).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/features/olympiades/presentation/olympiade_inscription_page.dart';

Widget _host({
  required int prixParticipation,
  String prixDesc = '',
  String reglement = '',
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: OlympiadeInscriptionPage(
      olympiadeId: 1,
      titre: 'Grand Prix Yéki',
      reglement: reglement,
      prixDesc: prixDesc,
      datDebut: DateTime.now().add(const Duration(days: 3)),
      datFin: DateTime.now().add(const Duration(days: 3, hours: 2)),
      prixParticipation: prixParticipation,
    ),
  );
}

// Le contenu de cet écran (calendrier, compte à rebours, participation,
// récompense, règlement, anti-triche, acceptation, bouton) dépasse les
// 600 px de hauteur par défaut du viewport de test : sans l'agrandir, le
// bouton final est scrollé hors champ et exclu par les finders
// `find.text*`/`find.byType` (`skipOffstage: true` par défaut, un
// comportement Flutter standard — pas un bug de l'écran).
void _agrandirViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  // `olympiade_inscription_page.dart` formate ses dates en `fr_FR` — comme
  // en production (`main.dart` appelle déjà `initializeDateFormatting`),
  // mais jamais fait automatiquement dans l'environnement de test.
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('OlympiadeInscriptionPage', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      _agrandirViewport(tester);
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(prixParticipation: 100, brightness: brightness));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('olympiade payante → bouton "Payer … et m\'inscrire" + carte Participation', (tester) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 100));
      await tester.pump();

      expect(find.textContaining('Payer 100 FCFA'), findsOneWidget);
      expect(find.text('Participation'), findsOneWidget);
    });

    testWidgets('olympiade gratuite → bouton "Confirmer mon inscription", pas de carte Participation', (
      tester,
    ) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 0));
      await tester.pump();

      expect(find.text('Confirmer mon inscription'), findsOneWidget);
      expect(find.text('Participation'), findsNothing);
      expect(find.textContaining('Payer'), findsNothing);
    });

    testWidgets('bouton désactivé tant que le règlement n\'est pas accepté', (tester) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 0));
      await tester.pump();

      final bouton = tester.widget<YkButton>(find.byType(YkButton).last);
      expect(bouton.onPressed, isNull);
    });

    testWidgets('bouton activé après acceptation du règlement', (tester) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 0));
      await tester.pump();

      await tester.tap(find.textContaining("J'ai lu et j'accepte"));
      await tester.pump();

      final bouton = tester.widget<YkButton>(find.byType(YkButton).last);
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('affiche la récompense via YkRichViewer quand prixDesc est fourni', (tester) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 0, prixDesc: '<p>Un trophée</p>'));
      await tester.pump();

      expect(find.byType(YkRichViewer), findsOneWidget);
    });

    testWidgets('YkCountdown affiché avant le début de la compétition', (tester) async {
      _agrandirViewport(tester);
      await tester.pumpWidget(_host(prixParticipation: 0));
      await tester.pump();

      expect(find.byType(YkCountdown), findsOneWidget);
    });
  });
}
