// Vérifie l'onglet « Paiements à valider » du dashboard Service Client
// (P9.5) : états chargement/erreur/vide/données, et la bascule cartes
// (compact) / YkDataTable (large) — même convention que
// design_data_test.dart::YkDataTable. Le contrôleur est construit
// directement avec des données injectées (champs publics, aucun appel
// réseau nécessaire) : pas de dépendance à l'infrastructure réseau
// absente en test (voir retrait_page_test.dart pour le cas où le réseau
// est, lui, sollicité).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:yeki/features/service_client/presentation/service_client_controller.dart';
import 'package:yeki/features/service_client/presentation/widgets/paiements_a_valider_tab.dart';
import 'package:yeki/models/paiement_models.dart';

Widget _host(Widget child, {Size size = const Size(800, 800)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

DemandePaiementManuel _demande({String? apprenant}) => DemandePaiementManuel(
  id: 1,
  categorie: 'abonnement',
  montant: 5000,
  montantConstate: null,
  operateur: 'orange_money',
  idTransaction: 'TX123',
  numeroEmetteur: '699000000',
  statut: 'en_attente',
  motifRefus: '',
  dateCreation: DateTime(2026, 7, 1, 10, 30),
  dateTraitement: null,
  apprenant: apprenant,
);

void main() {
  // `PaiementsAValiderTab` formate ses dates en `fr_FR` — comme en
  // production (`main.dart` appelle déjà `initializeDateFormatting`), mais
  // jamais fait automatiquement dans l'environnement de test.
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('PaiementsAValiderTab', () {
    testWidgets('affiche le skeleton pendant le chargement', (tester) async {
      final controller = ServiceClientController()..chargementPaiements = true;
      await tester.pumpWidget(_host(PaiementsAValiderTab(controller: controller)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un état vide sans demande', (tester) async {
      final controller = ServiceClientController()
        ..chargementPaiements = false
        ..paiements = const [];
      await tester.pumpWidget(_host(PaiementsAValiderTab(controller: controller)));
      expect(find.text('Aucun paiement en attente'), findsOneWidget);
    });

    testWidgets('affiche un état d\'erreur si le chargement a échoué', (tester) async {
      final controller = ServiceClientController()
        ..chargementPaiements = false
        ..enErreurPaiements = true;
      await tester.pumpWidget(_host(PaiementsAValiderTab(controller: controller)));
      expect(find.text('Impossible de charger les paiements.'), findsOneWidget);
    });

    testWidgets('affiche les cartes en compact', (tester) async {
      final controller = ServiceClientController()
        ..chargementPaiements = false
        ..paiements = [_demande(apprenant: 'Jean Dupont')];
      await tester.pumpWidget(
        _host(PaiementsAValiderTab(controller: controller), size: const Size(360, 800)),
      );
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Jean Dupont'), findsOneWidget);
    });

    testWidgets('affiche un YkDataTable au-delà du compact', (tester) async {
      final controller = ServiceClientController()
        ..chargementPaiements = false
        ..paiements = [_demande(apprenant: 'Jean Dupont')];
      await tester.pumpWidget(
        _host(PaiementsAValiderTab(controller: controller), size: const Size(1200, 900)),
      );
      expect(find.byType(DataTable), findsOneWidget);
    });
  });
}
