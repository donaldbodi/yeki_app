// Vérifie YkAdaptiveScaffold et YkNavConfig (P4.6) : configuration des
// destinations par rôle, montage du bon type de navigation aux 5
// ruptures, et interactions (destination non câblée vs câblée, badges).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _scaffold({
  required Size size,
  required String role,
  String? selectedRouteName,
  ValueChanged<String>? onDestinationTap,
  Map<String, int> badges = const {},
  Widget? contextPanel,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      home: YkAdaptiveScaffold(
        groups: YkNavConfig.forRole(role),
        selectedRouteName: selectedRouteName,
        onDestinationTap: onDestinationTap ?? (_) {},
        userName: 'Test User',
        userRole: role,
        onSettings: () {},
        onLogout: () {},
        badges: badges,
        contextPanel: contextPanel,
        body: const SizedBox(),
      ),
    ),
  );
}

void main() {
  group('YkNavConfig', () {
    test('apprenant : 10 destinations, exactement 4 dans la barre compacte', () {
      final groups = YkNavConfig.forRole('apprenant');
      final flat = [for (final g in groups) ...g.destinations];
      expect(flat.length, 10);
      expect(flat.where((d) => d.inCompactBar).length, 4);
    });

    test('enseignant_cadre : contient Mon département, pas Mon parcours', () {
      final flat = [for (final g in YkNavConfig.forRole('enseignant_cadre')) ...g.destinations];
      expect(flat.any((d) => d.label == 'Mon département'), isTrue);
      expect(flat.any((d) => d.label == 'Mon parcours'), isFalse);
    });

    test('enseignant_admin : contient Mon parcours, pas Administration générale', () {
      final flat = [for (final g in YkNavConfig.forRole('enseignant_admin')) ...g.destinations];
      expect(flat.any((d) => d.label == 'Mon parcours'), isTrue);
      expect(flat.any((d) => d.label == 'Administration générale'), isFalse);
    });

    test('admin : contient Administration générale, pas Mon parcours', () {
      final flat = [for (final g in YkNavConfig.forRole('admin')) ...g.destinations];
      expect(flat.any((d) => d.label == 'Administration générale'), isTrue);
      expect(flat.any((d) => d.label == 'Mon parcours'), isFalse);
    });

    test('service_client : une seule destination, câblée vers le dashboard à onglets (P9.5)', () {
      final flat = [for (final g in YkNavConfig.forRole('service_client')) ...g.destinations];
      expect(flat.any((d) => d.label == 'Service Client' && d.isWired), isTrue);
      // Les 2 anciennes destinations stub ont été consolidées en une seule.
      expect(flat.any((d) => d.label == 'Paiements à valider'), isFalse);
      expect(flat.any((d) => d.label == 'Gestion des répétiteurs'), isFalse);
    });
  });

  group('YkAdaptiveScaffold — ruptures', () {
    testWidgets('compact (<600) monte une barre du bas, pas de rail', (tester) async {
      await tester.pumpWidget(_scaffold(size: const Size(599, 800), role: 'apprenant'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Cursus'), findsOneWidget);
    });

    testWidgets('medium (600-904) monte un NavigationRail replié', (tester) async {
      await tester.pumpWidget(_scaffold(size: const Size(700, 800), role: 'apprenant'));
      await tester.pumpAndSettle();
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('expanded (905-1239) monte un rail + en-tête persistant', (tester) async {
      await tester.pumpWidget(_scaffold(size: const Size(1000, 800), role: 'apprenant'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(YkAppBar), findsOneWidget);
    });

    testWidgets('large (1240-1599) monte la navbar déployée, pas de rail, pas de panneau', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          size: const Size(1300, 800),
          role: 'apprenant',
          contextPanel: const Text('PANEL'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Cursus'), findsOneWidget);
      expect(find.text('PANEL'), findsNothing);
    });

    testWidgets('xlarge (>=1600) affiche le panneau contextuel fourni', (tester) async {
      await tester.pumpWidget(
        _scaffold(
          size: const Size(1700, 900),
          role: 'apprenant',
          contextPanel: const Text('PANEL'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PANEL'), findsOneWidget);
    });

    testWidgets('xlarge sans contextPanel ne plante pas', (tester) async {
      await tester.pumpWidget(_scaffold(size: const Size(1700, 900), role: 'apprenant'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('YkAdaptiveScaffold — interactions', () {
    testWidgets('tap sur une destination non câblée affiche Bientôt disponible, ne notifie pas', (
      tester,
    ) async {
      String? tapped;
      await tester.pumpWidget(
        _scaffold(size: const Size(1300, 900), role: 'apprenant', onDestinationTap: (r) => tapped = r),
      );
      await tester.pumpAndSettle();
      // "Forum" : destination sans route globale (widget embarqué par
      // cours uniquement, voir yk_nav_config_apprenant.dart) — non câblée.
      // Plus bas dans la liste que "Accueil" (premier élément) : la faire
      // défiler dans la vue avant de taper (ListView virtualisée).
      await tester.scrollUntilVisible(find.text('Forum'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();
      expect(find.text('Bientôt disponible'), findsOneWidget);
      expect(tapped, isNull);
    });

    testWidgets('tap sur une destination câblée notifie avec le bon nom de route', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _scaffold(size: const Size(1300, 900), role: 'apprenant', onDestinationTap: (r) => tapped = r),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cursus'));
      await tester.pumpAndSettle();
      expect(tapped, 'dashboardCursus');
    });

    testWidgets('"Accueil" est désormais câblée (P11.1)', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _scaffold(size: const Size(1300, 900), role: 'apprenant', onDestinationTap: (r) => tapped = r),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accueil'));
      await tester.pumpAndSettle();
      expect(tapped, 'dashboardAccueil');
    });

    testWidgets('un badge fourni est visible sur la destination correspondante', (tester) async {
      await tester.pumpWidget(
        _scaffold(size: const Size(1300, 900), role: 'apprenant', badges: const {'devoirs': 3}),
      );
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });
  });
}
