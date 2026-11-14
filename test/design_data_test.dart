// Vérifie le lot « Données » ajouté en P4.7 : YkAvatar, YkBadge, YkProgress,
// YkStatCard, YkDataTable, YkTimeline, YkLeaderboard, YkRating, YkCountdown,
// YkKeyValue — rendu, et règles ciblées : YkDataTable bascule en cartes en
// compact (jamais de défilement horizontal sur téléphone) ; YkCountdown
// change de couleur aux seuils warning (25 %) / error (10 %).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

Widget _host(Widget child, {Size size = const Size(800, 800)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkAvatar / YkAvatarGroup', () {
    testWidgets('affiche l\'initiale de repli en l\'absence d\'image', (tester) async {
      await tester.pumpWidget(_host(const YkAvatar(fallbackText: 'Ada Lovelace')));
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toutes les tailles se rendent sans exception', (tester) async {
      for (final size in YkAvatarSize.values) {
        await tester.pumpWidget(_host(YkAvatar(fallbackText: 'Test', size: size)));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('YkAvatarGroup affiche le débordement +N', (tester) async {
      await tester.pumpWidget(
        _host(
          YkAvatarGroup(
            max: 2,
            avatars: const [
              YkAvatar(fallbackText: 'A'),
              YkAvatar(fallbackText: 'B'),
              YkAvatar(fallbackText: 'C'),
            ],
          ),
        ),
      );
      expect(find.text('+1'), findsOneWidget);
    });
  });

  group('YkBadge', () {
    testWidgets('numeric masqué à 0, plafonné à 99+', (tester) async {
      await tester.pumpWidget(_host(const YkBadge(count: 0)));
      expect(find.byType(Container), findsNothing);

      await tester.pumpWidget(_host(const YkBadge(count: 150)));
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('label exige un libellé', (tester) async {
      expect(() => YkBadge(variant: YkBadgeVariant.label), throwsAssertionError);
    });
  });

  group('YkProgress', () {
    testWidgets('les 3 formes se rendent sans exception, avec centerLabel pour xpRing', (
      tester,
    ) async {
      for (final shape in YkProgressShape.values) {
        await tester.pumpWidget(
          _host(YkProgress(shape: shape, value: 0.5, centerLabel: '50 XP')),
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.text('50 XP'), findsOneWidget);
    });
  });

  group('YkStatCard', () {
    testWidgets('affiche valeur, libellé et tendance', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkStatCard(
            value: '24',
            label: 'Cours actifs',
            trendLabel: '+12 %',
            trendPositive: true,
          ),
        ),
      );
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Cours actifs'), findsOneWidget);
      expect(find.text('+12 %'), findsOneWidget);
    });
  });

  group('YkDataTable — règle responsive', () {
    YkDataTable buildTable() => YkDataTable(
      columns: const [YkDataColumn(label: 'Nom'), YkDataColumn(label: 'Moyenne', numeric: true)],
      rows: [
        YkDataRowData(cells: [const Text('Ada'), const Text('16')]),
      ],
      cardBuilder: (context, i) => const Card(child: Text('Carte ligne')),
    );

    testWidgets('bascule en cartes en compact — jamais de DataTable/scroll horizontal', (
      tester,
    ) async {
      await tester.pumpWidget(_host(buildTable(), size: const Size(360, 800)));
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Carte ligne'), findsOneWidget);
    });

    testWidgets('affiche un DataTable natif au-delà du compact', (tester) async {
      await tester.pumpWidget(_host(buildTable(), size: const Size(1200, 900)));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Carte ligne'), findsNothing);
    });
  });

  group('YkTimeline', () {
    testWidgets('affiche une entrée par élément, dans l\'ordre', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkTimeline(
            entries: [
              YkTimelineEntry(title: 'Créé'),
              YkTimelineEntry(title: 'Publié'),
            ],
          ),
        ),
      );
      expect(find.text('Créé'), findsOneWidget);
      expect(find.text('Publié'), findsOneWidget);
    });
  });

  group('YkLeaderboard', () {
    testWidgets('affiche le podium à partir de 3 entrées', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkLeaderboard(
            entries: [
              YkLeaderboardEntry(rank: 1, name: 'Ada', points: 100),
              YkLeaderboardEntry(rank: 2, name: 'Kofi', points: 90),
              YkLeaderboardEntry(rank: 3, name: 'Awa', points: 80),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.emoji_events), findsNWidgets(3));
    });

    testWidgets('sans podium si moins de 3 entrées', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkLeaderboard(
            entries: [YkLeaderboardEntry(rank: 1, name: 'Ada', points: 100)],
          ),
        ),
      );
      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });
  });

  group('YkRating', () {
    testWidgets('lecture seule sans onChanged, interactive sinon', (tester) async {
      int? changed;
      await tester.pumpWidget(
        _host(YkRating(value: 2, max: 5, onChanged: (v) => changed = v)),
      );
      await tester.tap(find.byIcon(Icons.star_rounded).first);
      expect(changed, isNotNull);

      await tester.pumpWidget(_host(const YkRating(value: 2, max: 5)));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('YkCountdown — seuils warning 25 % / error 10 %', () {
    testWidgets('couleur accent au départ, warning puis error selon les seuils', (tester) async {
      await tester.pumpWidget(
        _host(YkCountdown(duration: const Duration(seconds: 20), onExpired: () {})),
      );
      Color colorOf(WidgetTester t) =>
          t.widget<Icon>(find.byIcon(Icons.timer_outlined)).color!;

      final initial = colorOf(tester);
      expect(initial, YkColors.accent(tester.element(find.byType(YkCountdown))));

      // 16 s écoulées → 4 s restantes = 20 % (≤ 25 % warning, > 10 % error).
      await tester.pump(const Duration(seconds: 16));
      expect(colorOf(tester), YkColors.warning);

      // 3 s de plus → 1 s restante = 5 % (≤ 10 % error).
      await tester.pump(const Duration(seconds: 3));
      expect(colorOf(tester), YkColors.error);
    });

    testWidgets('onExpired appelé une fois le temps écoulé', (tester) async {
      var expired = false;
      await tester.pumpWidget(
        _host(YkCountdown(duration: const Duration(seconds: 2), onExpired: () => expired = true)),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(expired, isTrue);
      expect(find.text('00:00'), findsOneWidget);
    });
  });

  group('YkKeyValue', () {
    testWidgets('affiche le libellé et la valeur', (tester) async {
      await tester.pumpWidget(_host(const YkKeyValue(label: 'Niveau', value: '6e')));
      expect(find.text('Niveau'), findsOneWidget);
      expect(find.text('6e'), findsOneWidget);
    });
  });
}
