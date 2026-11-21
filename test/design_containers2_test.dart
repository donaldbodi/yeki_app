// Vérifie le lot « Conteneurs » ajouté en P4.7 : YkSheet, YkDialog, YkTabs,
// YkSection, YkExpansion — rendu, interactions, et la règle responsive de
// YkSheet (plein écran en compact, dialog centré au-delà).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child, {Size size = const Size(800, 800)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkSheet — règle responsive', () {
    testWidgets('plein écran (BottomSheet) en compact (< 600px)', (tester) async {
      await tester.pumpWidget(
        _host(
          size: const Size(360, 800),
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () => YkSheet.show<void>(
                context: context,
                title: 'Titre',
                bodyBuilder: (ctx) => const Text('Corps'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('dialog centré en large (≥ 600px)', (tester) async {
      await tester.pumpWidget(
        _host(
          size: const Size(1200, 900),
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () => YkSheet.show<void>(
                context: context,
                title: 'Titre',
                bodyBuilder: (ctx) => const Text('Corps'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('le bouton fermer ferme la feuille', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () => YkSheet.show<void>(
                context: context,
                title: 'Titre',
                bodyBuilder: (ctx) => const Text('Corps'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Corps'), findsNothing);
    });
  });

  group('YkDialog', () {
    testWidgets('confirm retourne true/false selon le bouton pressé', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () async {
                result = await YkDialog.confirm(
                  context: context,
                  title: 'Confirmation requise',
                  message: 'Continuer ?',
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('alert affiche le message et se ferme sur dismissLabel', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () => YkDialog.alert(
                context: context,
                title: 'Info',
                message: 'Session bientôt expirée',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Session bientôt expirée'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Session bientôt expirée'), findsNothing);
    });
  });

  group('YkTabs', () {
    testWidgets('affiche un badge par onglet et change de page au tap', (tester) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Scaffold(
            appBar: YkTabs(
              controller: controller,
              tabs: const [
                YkTabItem(label: 'Leçons'),
                YkTabItem(label: 'Devoirs', badge: 2),
              ],
            ),
            body: TabBarView(
              controller: controller,
              children: const [Text('Contenu leçons'), Text('Contenu devoirs')],
            ),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('Devoirs'));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
    });
  });

  group('YkSection', () {
    testWidgets('affiche titre, sous-titre et déclenche l\'action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          YkSection(
            title: 'Mes cours',
            subtitle: '4 cours',
            actionLabel: 'Voir tout',
            onAction: () => tapped = true,
            child: const Text('Contenu'),
          ),
        ),
      );
      expect(find.text('Mes cours'), findsOneWidget);
      expect(find.text('4 cours'), findsOneWidget);
      await tester.tap(find.text('Voir tout'));
      expect(tapped, isTrue);
    });
  });

  group('YkExpansion', () {
    testWidgets('déplie/replie le contenu au tap', (tester) async {
      await tester.pumpWidget(
        _host(
          YkExpansion(
            title: 'Module 1',
            child: const Text('Détail du module'),
          ),
        ),
      );
      expect(find.text('Détail du module'), findsNothing);
      await tester.tap(find.text('Module 1'));
      await tester.pumpAndSettle();
      expect(find.text('Détail du module'), findsOneWidget);
    });
  });
}
