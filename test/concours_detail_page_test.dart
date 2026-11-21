// Vérifie la refonte P8.3 de l'écran « détail concours » : rendu sans
// exception avec un `deptPrecharge` (chemin normal, `state.extra` du
// router), affichage des 3 onglets (Infos/Cours/Débouchés), et tolérance
// au réseau quand `deptPrecharge` est absent (bug corrigé : l'ancien
// fichier appelait `${baseUrl}/departement/<id>/`, une route inexistante
// côté backend faute du préfixe `apprenant/`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:yeki/features/olympiades/presentation/concours_detail_page.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';

DepartementItem _departement({String debouches = '', DateTime? dateLimiteInscription}) => DepartementItem(
  id: 1,
  nom: 'Prépa ENAM',
  description: 'Préparation complète au concours ENAM.',
  couleur: '#1A5276',
  prix: 15000,
  prixPresentiel: 0,
  nbCours: 3,
  progressionMoyenne: 40,
  statut: 'PUBLIE',
  nomConcours: 'Concours ENAM 2026',
  organismeConcours: 'ENAM',
  arreteMinisteriel: 'Arrêté n° 123/MINFOPRA',
  lienOfficiel: 'https://enam.cm',
  niveauxCibles: 'Licence',
  niveauxAccessibles: const ['Licence'],
  placesDisponibles: 50,
  fraisDossier: 5000,
  debouches: debouches,
  estFormationMetier: false,
  estFormationClassique: false,
  dureeFormation: '3 mois',
  modeFormation: 'en_ligne',
  modeFormationLabel: 'En ligne',
  certificatDelivre: '',
  prerequis: '',
  objectifs: '',
  domaine: 'Administration publique',
  ville: '',
  estCertifiante: false,
  cours: const [],
  progression: 0,
  accesRestreint: false,
  estAccessible: true,
  demandeStatut: '',
  dateLimiteInscription: dateLimiteInscription,
);

Widget _host({DepartementItem? dept, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: ConcoursDetailPage(concoursId: 1, deptPrecharge: dept),
  );
}

void main() {
  // `concours_detail_page.dart` formate ses dates en `fr_FR` — comme en
  // production (`main.dart` appelle déjà `initializeDateFormatting`), mais
  // jamais fait automatiquement dans l'environnement de test.
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('ConcoursDetailPage', () {
    testWidgets('avec deptPrecharge : se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(dept: _departement(), brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('avec deptPrecharge : affiche le nom du concours et les 3 onglets', (tester) async {
      await tester.pumpWidget(_host(dept: _departement()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Concours ENAM 2026'), findsWidgets);
      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Cours'), findsOneWidget);
      expect(find.text('Débouchés'), findsOneWidget);
    });

    testWidgets('débouchés vides → YkEmptyState sur le 3e onglet', (tester) async {
      await tester.pumpWidget(_host(dept: _departement(debouches: '')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Débouchés'));
      await tester.pumpAndSettle();

      expect(find.text('Débouchés non précisés'), findsOneWidget);
    });

    testWidgets('avec une date de clôture (formatage fr_FR) : se rend sans exception', (tester) async {
      await tester.pumpWidget(
        _host(dept: _departement(dateLimiteInscription: DateTime(2026, 9, 15))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('septembre 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans deptPrecharge : ne plante pas si le réseau échoue', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
