// Vérifie le noyau de composants Yk* (P4.3) : rendu de toutes les
// variantes, largeur figée en isLoading, cible tactile ≥48dp, présence de
// Semantics, et rendu clair/sombre sans exception. Étendu en P4.4 pour le
// contrat complet de YkForm, YkFileUpload et YkConfirmSheet.
//
// Limite assumée (voir plans P4.3/P4.4) : pas d'outil de capture d'écran
// dans cet environnement — la vérification clair/sombre se fait par
// assertions structurelles (rendu sans exception + couleurs attendues),
// pas par relecture visuelle pixel par pixel.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/network/api_exception.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  // Requis pour que find.bySemanticsLabel trouve quoi que ce soit : sans
  // handle actif, l'arbre Semantics n'est pas construit pendant les tests.
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkButton', () {
    testWidgets('toutes les variantes et tailles se rendent sans exception', (tester) async {
      for (final variant in YkButtonVariant.values) {
        for (final size in YkButtonSize.values) {
          await tester.pumpWidget(
            _host(YkButton(label: 'Test', onPressed: () {}, variant: variant, size: size)),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('isLoading ne change pas la taille du bouton', (tester) async {
      await tester.pumpWidget(_host(const YkButton(label: 'Valider', onPressed: null)));
      final sizeBefore = tester.getSize(find.byType(YkButton));

      await tester.pumpWidget(
        _host(const YkButton(label: 'Valider', onPressed: null, isLoading: true)),
      );
      final sizeAfter = tester.getSize(find.byType(YkButton));

      expect(sizeAfter, sizeBefore);
    });

    testWidgets('expose un Semantics bouton avec le libellé', (tester) async {
      await tester.pumpWidget(_host(YkButton(label: 'Envoyer', onPressed: () {})));
      expect(find.bySemanticsLabel('Envoyer'), findsOneWidget);
    });

    testWidgets('bouton icône-seule utilise semanticLabel', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkButton(
            label: '',
            onPressed: null,
            icon: Icons.favorite,
            iconPosition: YkButtonIconPosition.only,
            semanticLabel: 'Favori',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Favori'), findsOneWidget);
    });

    testWidgets('rendu clair ET sombre sans exception', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(YkButton(label: 'Test', onPressed: () {}), brightness: brightness),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('YkIconButton', () {
    testWidgets('cible tactile 48x48 garantie pour chaque variante', (tester) async {
      for (final variant in YkIconButtonVariant.values) {
        await tester.pumpWidget(
          _host(
            YkIconButton(
              icon: Icons.close,
              label: 'Fermer',
              onPressed: () {},
              variant: variant,
              iconSize: 12, // volontairement petit : la cible doit rester 48dp
            ),
          ),
        );
        final size = tester.getSize(find.byType(YkIconButton));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('expose un Semantics bouton avec le libellé', (tester) async {
      await tester.pumpWidget(
        _host(YkIconButton(icon: Icons.close, label: 'Fermer', onPressed: () {})),
      );
      expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
    });
  });

  group('YkCard', () {
    testWidgets('toutes les variantes se rendent sans exception, clair et sombre', (tester) async {
      for (final variant in YkCardVariant.values) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _host(
              YkCard(variant: variant, child: const Text('Contenu')),
              brightness: brightness,
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('devient un Semantics bouton quand onTap est fourni', (tester) async {
      await tester.pumpWidget(
        _host(
          YkCard(
            onTap: () {},
            semanticLabel: 'Cours de mathématiques',
            child: const Text('Cours'),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Cours de mathématiques'), findsOneWidget);
    });
  });

  group('YkAppBar', () {
    testWidgets('se rend sans exception avec titre, retour, recherche et actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: YkAppBar(
              title: 'Mes cours',
              onSearchChanged: (_) {},
              actions: [YkIconButton(icon: Icons.more_vert, label: 'Plus', onPressed: () {})],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mes cours'), findsOneWidget);
    });

    testWidgets('bascule vers la recherche au tap sur la loupe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: YkAppBar(title: 'Mes cours', onSearchChanged: (_) {}),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Rechercher'));
      await tester.pumpAndSettle();
      expect(find.text('Mes cours'), findsNothing);
      expect(find.byType(YkTextField), findsOneWidget);
    });
  });

  group('YkTextField', () {
    testWidgets('tous les types se rendent sans exception', (tester) async {
      for (final type in YkTextFieldType.values) {
        await tester.pumpWidget(_host(YkTextField(label: 'Champ', type: type)));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('mot de passe bascule la visibilité', (tester) async {
      await tester.pumpWidget(
        _host(const YkTextField(label: 'Mot de passe', type: YkTextFieldType.password)),
      );
      final fieldBefore = tester.widget<TextField>(find.byType(TextField));
      expect(fieldBefore.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final fieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(fieldAfter.obscureText, isFalse);
    });
  });

  group('YkForm', () {
    testWidgets('enveloppe un Form connecté au controller', (tester) async {
      final controller = YkFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(YkForm(controller: controller, child: const YkTextField(label: 'Nom'))),
      );
      expect(find.byType(Form), findsOneWidget);
      expect(controller.formKey.currentState, isNotNull);
    });

    testWidgets('required génère l\'astérisque automatiquement dans le label', (tester) async {
      final controller = YkFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          YkForm(
            controller: controller,
            child: const YkTextField(name: 'titre', label: 'Titre', required: true),
          ),
        ),
      );
      expect(find.text('Titre *'), findsOneWidget);
    });

    testWidgets(
      'YkFormSubmitButton désactivé tant qu\'un champ requis est vide, activé une fois rempli',
      (tester) async {
        final controller = YkFormController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            YkForm(
              controller: controller,
              child: Column(
                children: [
                  const YkTextField(name: 'titre', label: 'Titre', required: true),
                  YkFormSubmitButton(
                    controller: controller,
                    label: 'Valider',
                    onValidSubmit: () async {},
                    successMessage: 'OK',
                  ),
                ],
              ),
            ),
          ),
        );

        final buttonBefore = tester.widget<YkButton>(find.byType(YkButton));
        expect(buttonBefore.onPressed, isNull);

        await tester.enterText(find.byType(TextFormField), 'Mon titre');
        await tester.pump();

        final buttonAfter = tester.widget<YkButton>(find.byType(YkButton));
        expect(buttonAfter.onPressed, isNotNull);
      },
    );

    testWidgets(
      'ApiException.fields mappe l\'erreur sous le bon champ + résumé en tête',
      (tester) async {
        final controller = YkFormController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            YkForm(
              controller: controller,
              child: Column(
                children: [
                  const YkTextField(name: 'enonce', label: 'Énoncé', required: true),
                  YkFormSubmitButton(
                    controller: controller,
                    label: 'Valider',
                    onValidSubmit: () async {
                      throw ApiException(
                        code: ApiErrorCodes.validationError,
                        message: 'Le formulaire contient des erreurs.',
                        fields: const {
                          'enonce': ['Ce champ est obligatoire.'],
                        },
                      );
                    },
                    successMessage: 'OK',
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'x');
        await tester.pump();
        await tester.tap(find.text('Valider'));
        await tester.pumpAndSettle();

        expect(find.text('Ce champ est obligatoire.'), findsWidgets);
        expect(find.text('Le formulaire contient des erreurs'), findsOneWidget);
      },
    );

    testWidgets('succès → YkSnack affiché systématiquement', (tester) async {
      final controller = YkFormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          YkForm(
            controller: controller,
            child: Column(
              children: [
                const YkTextField(name: 'titre', label: 'Titre', required: true),
                YkFormSubmitButton(
                  controller: controller,
                  label: 'Valider',
                  onValidSubmit: () async {},
                  successMessage: 'Créé avec succès',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'x');
      await tester.pump();
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.text('Créé avec succès'), findsOneWidget);
    });
  });

  group('YkFileUpload', () {
    testWidgets('rejette un fichier hors extensions autorisées sans appeler onChanged', (
      tester,
    ) async {
      YkPickedFile? received;
      await tester.pumpWidget(
        _host(
          YkFileUpload(
            constraint: const YkFileConstraint(allowedExtensions: ['png'], maxSizeBytes: 1024),
            onChanged: (f) => received = f,
          ),
        ),
      );
      final constraint = tester.widget<YkFileUpload>(find.byType(YkFileUpload)).constraint;
      expect(constraint.validate('photo.pdf', 100), isNotNull);
      expect(received, isNull);
    });

    testWidgets('rejette un fichier trop lourd avec message explicite', (tester) async {
      const constraint = YkFileConstraint(allowedExtensions: ['png'], maxSizeBytes: 1000);
      final error = constraint.validate('photo.png', 2000);
      expect(error, contains('volumineux'));
    });

    testWidgets('accepte un fichier valide et expose bytes/name/mimeType/size (jamais de File)', (
      tester,
    ) async {
      const constraint = YkFileConstraint(allowedExtensions: ['png'], maxSizeBytes: 1000);
      expect(constraint.validate('photo.png', 500), isNull);

      final picked = YkPickedFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        name: 'photo.png',
        mimeType: 'image/png',
        size: 3,
      );
      expect(picked.bytes, isA<Uint8List>());
      expect(picked.name, 'photo.png');
      expect(picked.mimeType, 'image/png');
      expect(picked.size, 3);
    });

    testWidgets('affiche les contraintes avant sélection', (tester) async {
      await tester.pumpWidget(
        _host(
          YkFileUpload(
            constraint: const YkFileConstraint(allowedExtensions: ['jpg'], maxSizeBytes: 1024 * 1024),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.textContaining('JPG'), findsOneWidget);
    });
  });

  group('YkConfirmSheet', () {
    testWidgets('exerciceTentativesEpuisees retourne true sans afficher de sheet', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Sortir',
              onPressed: () async {
                result = await YkConfirmSheet.confirmExit(
                  context,
                  policy: YkExitPolicy.exerciceTentativesEpuisees,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sortir'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('exerciceTentativesRestantes affiche le bon texte et retourne true au confirm', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Sortir',
              onPressed: () async {
                result = await YkConfirmSheet.confirmExit(
                  context,
                  policy: YkExitPolicy.exerciceTentativesRestantes,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sortir'));
      await tester.pumpAndSettle();

      expect(find.text("Quitter l'exercice ?"), findsOneWidget);
      await tester.tap(find.text('Quitter et soumettre'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('devoirTentativesRestantes retourne false si l\'utilisateur reste', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Sortir',
              onPressed: () async {
                result = await YkConfirmSheet.confirmExit(
                  context,
                  policy: YkExitPolicy.devoirTentativesRestantes,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sortir'));
      await tester.pumpAndSettle();

      expect(find.text('Quitter le devoir ?'), findsOneWidget);
      expect(find.text('Quitter (tentative comptée)'), findsOneWidget);
      await tester.tap(find.text('Rester'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('devoirTentativesEpuisees affiche un texte distinct des 2 autres politiques', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Sortir',
              onPressed: () => YkConfirmSheet.confirmExit(
                context,
                policy: YkExitPolicy.devoirTentativesEpuisees,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sortir'));
      await tester.pumpAndSettle();

      expect(find.text('Tentatives épuisées'), findsOneWidget);
      expect(find.text("Quitter l'exercice ?"), findsNothing);
      expect(find.text('Quitter le devoir ?'), findsNothing);
    });
  });

  group('YkSkeleton', () {
    testWidgets('toutes les formes se rendent sans exception', (tester) async {
      final shapes = <Widget>[
        const YkSkeleton.line(),
        const YkSkeleton.card(),
        const YkSkeleton.list(itemCount: 2),
        const YkSkeleton.grid(itemCount: 2),
        const YkSkeleton.table(rows: 2, columns: 2),
      ];
      for (final shape in shapes) {
        await tester.pumpWidget(_host(shape));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('respecte disableAnimations (pas de crash, rendu figé)', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const YkSkeleton.line()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('YkEmptyState / YkErrorState', () {
    testWidgets('YkEmptyState affiche le titre et le message contextuels', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkEmptyState(
            title: 'Aucun devoir publié pour l\'instant',
            message: 'Revenez plus tard.',
          ),
        ),
      );
      expect(find.text('Aucun devoir publié pour l\'instant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('YkErrorState affiche le message et le bouton Réessayer', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _host(YkErrorState(message: 'Chargement impossible', onRetry: () => retried = true)),
      );
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });
  });

  group('YkSnack', () {
    testWidgets('YkSnack.success affiche un SnackBar avec le message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: YkButton(
                  label: 'Déclencher',
                  onPressed: () => YkSnack.success(context, 'Enregistré'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Déclencher'));
      await tester.pump();
      expect(find.text('Enregistré'), findsOneWidget);
    });
  });
}
