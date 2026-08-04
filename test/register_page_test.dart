// Vérifie la refonte P5.4 de l'écran Inscription : rendu sans exception,
// gating du bouton "Suivant" par étape, et le parcours enseignant (qui
// saute Parcours/Département/Niveau, ne dépend d'aucune donnée réseau —
// contrairement au parcours apprenant, qui a besoin d'une vraie liste de
// parcours). Même limite que P5.3 : aucune infrastructure de mock
// ApiClient/dio dans ce projet — `FormationRepository().parcours()`
// tente un vrai appel réseau en test, échec toléré (géré par le
// try/catch de `_loadParcours`, résultat : liste vide).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/features/register/presentation/register_page.dart';

Widget _host() {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Text('Écran de connexion'),
      ),
    ],
  );
  // Délégués de localisation requis pour piloter `YkDateTimePicker`
  // (date de naissance, `showDatePicker` Material) dans les tests — sans
  // eux, ouvrir le sélecteur lève une exception (mêmes délégués que
  // `main.dart`).
  return MaterialApp.router(
    locale: const Locale('fr', 'CM'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('fr', 'CM'), Locale('fr')],
    routerConfig: router,
  );
}

Future<void> _remplirIdentite(
  WidgetTester tester, {
  String name = 'Aïcha Ndongo',
  String username = 'aicha_n',
  String email = 'aicha@yeki.test',
  String phone = '690000000',
  String password = 'motdepasse123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), username);
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), phone);
  await tester.enterText(fields.at(4), password);
  await tester.enterText(fields.at(5), password);
  await tester.pump();

  // Date de naissance : `YkDateTimePicker` n'est pas un `TextFormField` —
  // ouvre le sélecteur Material et confirme la date proposée par défaut
  // (`initialDate: DateTime.now()`), suffisant pour satisfaire la
  // validation "requis", peu importe la date exacte choisie en test.
  // `ensureVisible` avant le tap (le champ peut être hors du viewport
  // réduit du test) ; `pump(duration)` plutôt que `pumpAndSettle()` après
  // ouverture du dialogue Material (son animation d'entrée ne "settle"
  // jamais dans l'environnement de test, `pumpAndSettle` y expire).
  final champDate = find.text('Choisir une date');
  await tester.ensureVisible(champDate);
  await tester.pump();
  await tester.tap(champDate);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text('OK'));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Rendu', () {
    testWidgets('se rend sans exception et affiche l\'étape Identité', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Créez votre compte'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });
  });

  group('Validation locale — étape Identité', () {
    testWidgets('le bouton "Suivant" est désactivé tant que les champs requis sont vides', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Champs vides : "Suivant" ne fait rien, l'étape ne change pas.
      await tester.tap(find.text('Suivant'));
      await tester.pump();
      expect(find.text('Créez votre compte'), findsOneWidget);

      await _remplirIdentite(tester);

      // Champs remplis : "Suivant" avance bien vers l'étape Parcours.
      await tester.tap(find.text('Suivant'));
      await tester.pump();
      expect(find.text('Votre parcours'), findsOneWidget);
    });
  });

  group('Parcours enseignant (aucune dépendance réseau)', () {
    testWidgets(
      'saute Parcours/Département/Niveau, va directement à la Confirmation, '
      'et conserve la saisie en revenant en arrière',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Enseignant'));
        await tester.pump();

        await _remplirIdentite(tester, name: 'Jean Mballa', username: 'jean_m');

        await tester.tap(find.text('Suivant'));
        await tester.pump();

        // Directement sur la Confirmation — jamais de résumé
        // Parcours/Département/Niveau pour un enseignant.
        expect(find.text('Vérifiez vos informations avant de créer votre compte.'), findsOneWidget);
        expect(find.text('Créer mon compte'), findsOneWidget);
        expect(find.text('Votre parcours'), findsNothing);

        await tester.tap(find.text('Précédent'));
        await tester.pump();

        // De retour sur l'étape Identité, avec la saisie intacte —
        // preuve que l'IndexedStack garde les 5 étapes montées.
        expect(find.text('Créez votre compte'), findsOneWidget);
        final fields = find.byType(TextFormField);
        expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, 'Jean Mballa');
      },
    );
  });

  group('Navigation', () {
    testWidgets('"Déjà un compte ? Se connecter" ouvre l\'écran de connexion', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Déjà un compte ? Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Écran de connexion'), findsOneWidget);
    });
  });
}
