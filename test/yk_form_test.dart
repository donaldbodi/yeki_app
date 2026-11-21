// Vérifie le correctif P5.3 de `YkFormController.submit()` (composant
// partagé, `lib/core/design/components/inputs/yk_form.dart`) : avant ce
// correctif, une `ApiException` dont `fields` est vide (ex. le backend lève
// une `ValidationError` de niveau formulaire, pas de champ précis —
// identifiants incorrects sur l'écran Connexion, voir
// docs/ecarts/login.md) ne remontait STRICTEMENT AUCUN feedback : ni
// bannière, ni erreur de champ, ni snackbar. `e.message` est maintenant
// injecté dans le résumé en tête quand `fields` ne produit rien.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/network/api_exception.dart';

/// `submit()` exige un `Form` réellement monté sous `controller.formKey`
/// (sinon `formKey.currentState` est `null` et `submit()` retourne avant
/// même d'appeler `onValidSubmit` — c'est `YkForm` qui monte ce `Form`).
/// Aucun `YkTextField` requis dans `child` : sans champ, `validate()` et
/// `canSubmit` sont trivialement vrais.
Future<BuildContext> _pumpForm(WidgetTester tester, YkFormController controller) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ctx = context;
          return YkForm(controller: controller, child: const SizedBox());
        },
      ),
    ),
  );
  return ctx;
}

void main() {
  group('YkFormController.submit()', () {
    testWidgets('ApiException sans fields : message publié dans le résumé, jamais silencieux', (
      tester,
    ) async {
      final controller = YkFormController();
      addTearDown(controller.dispose);
      final context = await _pumpForm(tester, controller);

      await controller.submit(
        context: context,
        onValidSubmit: () async => throw const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'Identifiants incorrects.',
          fields: {},
        ),
        successMessage: 'ok',
      );

      expect(controller.summaryErrors, contains('Identifiants incorrects.'));
    });

    testWidgets('ApiException avec fields : mapping par champ inchangé (pas de régression)', (
      tester,
    ) async {
      final controller = YkFormController();
      addTearDown(controller.dispose);
      final context = await _pumpForm(tester, controller);

      await controller.submit(
        context: context,
        onValidSubmit: () async => throw const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'Le formulaire contient des erreurs.',
          fields: {
            'identifier': ['Ce champ est requis.'],
          },
        ),
        successMessage: 'ok',
      );

      expect(controller.errorFor('identifier'), 'Ce champ est requis.');
      expect(controller.summaryErrors, isNot(contains('Le formulaire contient des erreurs.')));
    });
  });

  group('YkFormController.registerField()', () {
    test('initiallyFilled: true rend canSubmit vrai sans notifyListeners() supplémentaire', () {
      // P8.2 : un champ requis PRÉ-REMPLI (valeur par défaut, mode
      // édition) doit être immédiatement pris en compte SANS notifier —
      // avant le correctif, seul `registerField` (toujours `filled:
      // false`) puis un `updateFieldFilled` séparé faisaient ce travail,
      // ce qui notifiait pendant la construction de l'arbre (le
      // `AnimatedBuilder` de `YkForm` étant lui-même en cours de build)
      // et levait `setState() called during build` — reproduit par
      // `YkTextField` avec un `TextEditingController` pré-rempli, dans un
      // `YkForm` (voir `test/creer_olympiade_sheet_test.dart`).
      final controller = YkFormController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.registerField('titre', required: true, initiallyFilled: true);

      expect(controller.canSubmit, isTrue);
      expect(notifications, 0);
    });

    test('initiallyFilled par défaut à false (comportement inchangé)', () {
      final controller = YkFormController();
      addTearDown(controller.dispose);

      controller.registerField('titre', required: true);

      expect(controller.canSubmit, isFalse);
    });
  });
}
