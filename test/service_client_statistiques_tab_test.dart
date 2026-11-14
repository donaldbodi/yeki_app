// Vérifie l'onglet « Statistiques » du dashboard Service Client (P9.5) :
// 6 YkStatCard (demandes en attente / délai moyen / taux de refus ×2),
// et le repli "—" quand une moyenne n'est pas calculable (aucune demande
// traitée — jamais une fausse valeur à 0, voir ServiceClientStatistiques).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/service_client/presentation/service_client_controller.dart';
import 'package:yeki/features/service_client/presentation/widgets/statistiques_tab.dart';
import 'package:yeki/models/paiement_models.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('StatistiquesTab', () {
    testWidgets('affiche le skeleton pendant le chargement', (tester) async {
      final controller = ServiceClientController()..chargementStats = true;
      await tester.pumpWidget(_host(StatistiquesTab(controller: controller)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche un état d\'erreur si le chargement a échoué', (tester) async {
      final controller = ServiceClientController()
        ..chargementStats = false
        ..enErreurStats = true;
      await tester.pumpWidget(_host(StatistiquesTab(controller: controller)));
      expect(find.text('Impossible de charger les statistiques.'), findsOneWidget);
    });

    testWidgets('affiche les valeurs chiffrées quand des moyennes existent', (tester) async {
      final controller = ServiceClientController()
        ..chargementStats = false
        ..statistiques = const ServiceClientStatistiques(
          demandesEnAttentePaiement: 3,
          demandesEnAttenteRetrait: 1,
          delaiMoyenMinutesPaiement: 90,
          delaiMoyenMinutesRetrait: 30,
          tauxRefusPaiement: 12.5,
          tauxRefusRetrait: 0,
        );
      await tester.pumpWidget(_host(StatistiquesTab(controller: controller)));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('1.5 h'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('12.5 %'), findsOneWidget);
    });

    testWidgets('affiche "—" quand aucune moyenne n\'est calculable', (tester) async {
      final controller = ServiceClientController()
        ..chargementStats = false
        ..statistiques = const ServiceClientStatistiques(
          demandesEnAttentePaiement: 0,
          demandesEnAttenteRetrait: 0,
          delaiMoyenMinutesPaiement: null,
          delaiMoyenMinutesRetrait: null,
          tauxRefusPaiement: null,
          tauxRefusRetrait: null,
        );
      await tester.pumpWidget(_host(StatistiquesTab(controller: controller)));
      expect(find.text('—'), findsNWidgets(4));
    });
  });
}
