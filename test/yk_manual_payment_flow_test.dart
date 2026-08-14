// Vérifie YkManualPaymentFlow (P9.3) : rendu des 4 étapes (paiement/
// recharge) et des 3 étapes (retrait), validation de format de l'ID de
// transaction, bouton WhatsApp Service Client présent en confirmation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _show(
  WidgetTester tester, {
  required YkPaiementSens sens,
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onSoumettre,
}) async {
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (context) => YkButton(
          label: 'Ouvrir',
          onPressed: () {
            YkManualPaymentFlow.show(
              context,
              sens: sens,
              montant: 2000,
              titre: 'Abonnement mensuel',
              dureeAcces: '1 mois',
              ussdOrange: '#150*1#',
              ussdMtn: '*126#',
              numeroDepotOrange: '694000000',
              numeroDepotMtn: '670000000',
              nomAfficheDepot: 'YEKI SARL',
              whatsappServiceClient: '237600000000',
              delaiValidationMinutes: 60,
              onSoumettre: onSoumettre ?? (payload) async => {'id': 1, 'statut': 'en_attente'},
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('YkManualPaymentFlow — paiement/recharge (4 étapes)', () {
    testWidgets('affiche les 4 étapes et permet de les traverser jusqu\'à confirmation', (tester) async {
      await _show(tester, sens: YkPaiementSens.paiement);

      // Étape 1 — Récapitulatif.
      expect(find.text('Récapitulatif'), findsWidgets);
      expect(find.text('Abonnement mensuel'), findsOneWidget);
      expect(find.text('2000 FCFA'), findsOneWidget);
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Étape 2 — Instructions (USSD + nom affiché).
      expect(find.text('Instructions'), findsWidgets);
      expect(find.text('#150*1#'), findsOneWidget);
      expect(find.text('YEKI SARL'), findsOneWidget);
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Étape 3 — Saisie : ID de transaction trop court refusé.
      expect(find.text('Saisie'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'AB');
      await tester.ensureVisible(find.text('Envoyer'));
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('trop court'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'CI240912.1234.A56789');
      // P17.13 : « Votre numéro » est désormais obligatoire (3ᵉ champ de
      // cette étape, après identifiant de transaction et montant).
      await tester.enterText(find.byType(TextFormField).at(2), '690000000');
      await tester.ensureVisible(find.text('Envoyer'));
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();

      // Étape 4 — Confirmation.
      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.textContaining('60'), findsWidgets);
      expect(find.text('Contacter le Service Client'), findsOneWidget);
    });
  });

  group('YkManualPaymentFlow — retrait (3 étapes, sans Instructions)', () {
    testWidgets('saute l\'étape Instructions, exige un numéro de destination', (tester) async {
      await _show(tester, sens: YkPaiementSens.retrait);

      expect(find.text('Récapitulatif'), findsWidgets);
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Directement Saisie (pas d'étape Instructions pour un retrait).
      expect(find.text('Saisie'), findsWidgets);
      expect(find.text('Instructions'), findsNothing);
      expect(find.text('Numéro de destination *'), findsOneWidget);

      await tester.ensureVisible(find.text('Envoyer'));
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('obligatoire'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '690000000');
      await tester.ensureVisible(find.text('Envoyer'));
      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();

      expect(find.text('Demande de retrait envoyée'), findsOneWidget);
    });
  });
}
