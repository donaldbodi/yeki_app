// Vérifie l'onglet « Retraits à valider » du dashboard Service Client
// (P9.5) : mêmes états que l'onglet Paiements, plus l'exigence explicite
// du ticket — le solde actuel du bénéficiaire doit être visible avant
// traitement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:yeki/features/service_client/presentation/service_client_controller.dart';
import 'package:yeki/features/service_client/presentation/widgets/retraits_a_valider_tab.dart';
import 'package:yeki/models/paiement_models.dart';

Widget _host(Widget child, {Size size = const Size(800, 800)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

DemandeRetrait _demande({String? beneficiaire, int? soldeBeneficiaire}) => DemandeRetrait(
  id: 1,
  montantBrut: 10000,
  fraisOperateur: 200,
  montantNet: 9800,
  operateur: 'mtn_momo',
  numeroDestination: '677000000',
  statut: 'en_attente',
  motifRefus: '',
  dateCreation: DateTime(2026, 7, 1, 9, 0),
  dateTraitement: null,
  beneficiaire: beneficiaire,
  soldeBeneficiaire: soldeBeneficiaire,
);

void main() {
  // `RetraitsAValiderTab` formate ses dates en `fr_FR` — voir
  // service_client_paiements_tab_test.dart pour l'explication complète.
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('RetraitsAValiderTab', () {
    testWidgets('affiche un état vide sans demande', (tester) async {
      final controller = ServiceClientController()
        ..chargementRetraits = false
        ..retraits = const [];
      await tester.pumpWidget(_host(RetraitsAValiderTab(controller: controller)));
      expect(find.text('Aucun retrait en attente'), findsOneWidget);
    });

    testWidgets('affiche un état d\'erreur si le chargement a échoué', (tester) async {
      final controller = ServiceClientController()
        ..chargementRetraits = false
        ..enErreurRetraits = true;
      await tester.pumpWidget(_host(RetraitsAValiderTab(controller: controller)));
      expect(find.text('Impossible de charger les retraits.'), findsOneWidget);
    });

    testWidgets('affiche le solde du bénéficiaire dans les cartes en compact', (tester) async {
      final controller = ServiceClientController()
        ..chargementRetraits = false
        ..retraits = [_demande(beneficiaire: 'Cadre Test', soldeBeneficiaire: 25000)];
      await tester.pumpWidget(
        _host(RetraitsAValiderTab(controller: controller), size: const Size(360, 800)),
      );
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Cadre Test'), findsOneWidget);
      expect(find.textContaining('25000'), findsWidgets);
    });

    testWidgets('affiche un YkDataTable avec la colonne solde actuel au-delà du compact', (
      tester,
    ) async {
      final controller = ServiceClientController()
        ..chargementRetraits = false
        ..retraits = [_demande(beneficiaire: 'Cadre Test', soldeBeneficiaire: 25000)];
      await tester.pumpWidget(
        _host(RetraitsAValiderTab(controller: controller), size: const Size(1200, 900)),
      );
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Solde actuel'), findsOneWidget);
    });
  });
}
