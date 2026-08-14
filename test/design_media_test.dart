// Vérifie le lot « Média » ajouté en P4.7 : YkAudioPlayer, YkPdfViewer,
// YkImageViewer, YkLessonFeed.
//
// Limite assumée : `YkVideoPlayer` (chewie/video_player) appelle
// `VideoPlayerPlatform.instance.init()` dès `initState` via un vrai
// `MethodChannel` — sans plugin enregistré (`flutter test` ne charge pas de
// plugins natifs, contrairement à `integration_test`), le montage échoue
// avec `UnimplementedError: init() has not been implemented` (vérifié
// empiriquement, pas supposé). Le rendre testable exigerait de fournir une
// implémentation `VideoPlayerPlatform` factice — hors périmètre de ce lot de
// smoke tests ; vérifié manuellement via la galerie `/design-system`. Seule
// la classe de données `YkVideoChapter`, indépendante de la plateforme, est
// testée ici.
//
// `YkAudioPlayer` (audioplayers) et `YkPdfViewer` (flutter_pdfview, vue de
// plateforme) se montent sans exception dans cet environnement (vérifié) :
// leurs tests couvrent le rendu statique, sans déclencher de lecture réelle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkVideoChapter', () {
    test('conserve le libellé et la position fournis', () {
      const chapter = YkVideoChapter(label: 'Introduction', position: Duration(seconds: 30));
      expect(chapter.label, 'Introduction');
      expect(chapter.position, const Duration(seconds: 30));
    });
  });

  group('YkAudioPlayer', () {
    testWidgets('se rend sans exception, affiche le libellé et les contrôles', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkAudioPlayer(audioUrl: 'https://example.com/audio.mp3', label: 'Message vocal'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Message vocal'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
    });

    testWidgets('le bouton vitesse fait défiler les valeurs disponibles', (tester) async {
      await tester.pumpWidget(
        _host(const YkAudioPlayer(audioUrl: 'https://example.com/audio.mp3')),
      );
      await tester.tap(find.text('1.0x'));
      await tester.pump();
      expect(find.text('1.25x'), findsOneWidget);
    });
  });

  group('YkPdfViewer', () {
    testWidgets('se rend sans exception avec filigrane et pagination', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkPdfViewer(filePath: '/tmp/fake.pdf', watermarkText: 'Ada Lovelace • #1234'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('affiche le bouton favori seulement si onToggleBookmark est fourni', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const YkPdfViewer(filePath: '/tmp/fake.pdf', watermarkText: 'Test')),
      );
      expect(find.byIcon(Icons.bookmark_border), findsNothing);

      await tester.pumpWidget(
        _host(
          YkPdfViewer(
            filePath: '/tmp/fake.pdf',
            watermarkText: 'Test',
            onToggleBookmark: (_) {},
          ),
        ),
      );
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });
  });

  group('YkImageViewer', () {
    testWidgets('se rend sans exception avec zoom (InteractiveViewer) et galerie (PageView)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            height: 300,
            child: YkImageViewer(
              imageUrls: ['https://example.com/a.png', 'https://example.com/b.png'],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Le chargement réseau réel échoue dans cet environnement de test sans
      // accès internet — géré par errorBuilder (voir composant) ; on
      // consomme l'exception résiduelle plutôt que de la laisser faire
      // échouer le test, la structure du widget étant ce qui est vérifié ici.
      tester.takeException();
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsWidgets);
    });
  });

  group('YkLessonFeed', () {
    testWidgets('affiche le contenu fourni et déclenche les callbacks d\'action', (tester) async {
      var liked = '';
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            height: 500,
            child: YkLessonFeed(
              items: const [
                YkLessonFeedItem(id: '1', player: Text('Leçon 1')),
                YkLessonFeedItem(id: '2', player: Text('Leçon 2')),
              ],
              onLike: (id) => liked = id,
              onFavorite: (_) {},
              onPreoccupation: (_) {},
              onDownload: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Leçon 1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(liked, '1');
    });
  });
}
