// Vérifie YkRichEditor/YkRichViewer (P4.5) : conversion Delta<->HTML,
// rendu de l'éditeur (barres compacte/large, insertion de formule/image),
// et rendu du lecteur (formule → widget Math, pas du texte brut).
//
// Note : `flutter_quill` exige son propre délégué de localisation
// (`FlutterQuillLocalizations.delegate`) pour que la barre d'outils
// résolve ses libellés — absent de `main.dart` aujourd'hui puisqu'aucun
// écran n'utilise encore YkRichEditor (Phase 4). À ajouter lors de la
// première migration d'écran réelle.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/components/inputs/yk_rich_html_converter.dart';

Widget _host(Widget child, {Size size = const Size(800, 900)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('deltaToHtml / htmlToDelta', () {
    test('rend titre, gras/italique/souligné, liste, lien, image et formule', () {
      final delta = Delta()
        ..insert('Titre')
        ..insert('\n', {'header': 1})
        ..insert('gras', {'bold': true})
        ..insert(' et ')
        ..insert('italique', {'italic': true})
        ..insert(' et ')
        ..insert('souligné', {'underline': true})
        ..insert('\n')
        ..insert('un lien', {'link': 'https://yeki.cm'})
        ..insert('\n')
        ..insert('élément 1')
        ..insert('\n', {'list': 'bullet'})
        ..insert('élément 2')
        ..insert('\n', {'list': 'bullet'})
        ..insert({'yk-image': '{"url":"https://x/y.png","alt":"desc"}'})
        ..insert('\n')
        ..insert({'formula': r'\frac{1}{2}'})
        ..insert('\n');

      final html = deltaToHtml(delta);

      expect(html, contains('<h1>Titre</h1>'));
      expect(html, contains('<strong>gras</strong>'));
      expect(html, contains('<em>italique</em>'));
      expect(html, contains('<u>souligné</u>'));
      expect(html, contains('<a href="https://yeki.cm">un lien</a>'));
      expect(html, contains('<ul><li>élément 1</li><li>élément 2</li></ul>'));
      expect(html, contains('class="yk-image"'));
      expect(html, contains('alt="desc"'));
      expect(html, contains('class="yk-formula"'));
      expect(html, contains('data-latex'));
    });

    test('aller-retour HTML -> Delta reconnaît la formule et l\'image', () {
      const html =
          '<p>Texte <strong>gras</strong></p>'
          '<span class="yk-formula" data-latex="x^2">x^2</span>'
          '<img class="yk-image" src="https://x/y.png" alt="un chat">';

      final delta = htmlToDelta(html);
      final ops = delta.toList();

      final hasFormula = ops.any(
        (op) => op.data is Map && (op.data as Map).containsKey(BlockEmbed.formulaType),
      );
      final hasImage = ops.any(
        (op) => op.data is Map && (op.data as Map).containsKey('yk-image'),
      );
      final hasBold = ops.any(
        (op) => op.data == 'gras' && op.attributes?['bold'] == true,
      );

      expect(hasFormula, isTrue);
      expect(hasImage, isTrue);
      expect(hasBold, isTrue);
    });
  });

  group('YkRichEditor', () {
    testWidgets('se rend sans exception en large (barre complète permanente)', (tester) async {
      await tester.pumpWidget(
        _host(
          YkRichEditor(
            initialHtml: '<p>Bonjour</p>',
            onChanged: (_) {},
            onUploadImage: (file) async => 'https://x/uploaded.png',
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['png', 'jpg'],
              maxSizeBytes: 1024 * 1024,
            ),
            label: 'Énoncé',
          ),
          size: const Size(1400, 900),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byTooltip('Insérer une image'), findsOneWidget);
      expect(find.byTooltip('Insérer une formule'), findsOneWidget);
      expect(find.byTooltip('Insérer un emoji'), findsOneWidget);
    });

    testWidgets('se rend sans exception en compact (barre réduite + bouton …)', (tester) async {
      await tester.pumpWidget(
        _host(
          YkRichEditor(
            initialHtml: '',
            onChanged: (_) {},
            onUploadImage: (file) async => 'https://x/uploaded.png',
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['png'],
              maxSizeBytes: 1024,
            ),
            label: 'Énoncé',
          ),
          size: const Size(360, 700),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Plus de mise en forme (titres, alignement, lien)'), findsOneWidget);
    });

    testWidgets('un HTML initial malformé ne fait pas planter l\'éditeur', (tester) async {
      await tester.pumpWidget(
        _host(
          YkRichEditor(
            initialHtml: '<p><strong>oops',
            onChanged: (_) {},
            onUploadImage: (file) async => 'https://x/y.png',
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['png'],
              maxSizeBytes: 1024,
            ),
            label: 'Énoncé',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('YkRichViewer', () {
    testWidgets('un span yk-formula produit un widget Math, pas du texte brut', (tester) async {
      const html = '<p>Avant</p><span class="yk-formula" data-latex="x^2">x^2</span>';
      await tester.pumpWidget(_host(const YkRichViewer(html: html)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('x^2'), findsNothing);
    });

    testWidgets('html vide ne rend rien sans exception', (tester) async {
      await tester.pumpWidget(_host(const YkRichViewer(html: '')));
      expect(tester.takeException(), isNull);
    });
  });
}
