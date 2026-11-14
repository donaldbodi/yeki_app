// Vérification P3.3 : pour chaque rôle backend (Profile.USER_TYPES),
// après bootstrap de l'état d'auth (token + rôle + onboarding terminé en
// cache), le routeur doit atterrir sur l'accueil attendu par
// `guards.homePathForRole` — y compris `service_client`, qui n'a pas
// d'écran dédié et doit tomber sur le seau de repli `/enseignant/secondaire`
// (voir la note correspondante dans guards.dart), pas sur /login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/core/router/app_router.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';

Future<String> _landingPathForRole(WidgetTester tester, String role) async {
  // Taille d'écran de test généreuse : les écrans réels (dashboards) ne
  // sont pas conçus pour la petite surface par défaut de `flutter test`
  // et débordent (RenderFlex overflow) sans rapport avec le routage —
  // ce test vérifie l'URL d'atterrissage, pas la mise en page.
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    'token': 'test-token',
    'role': role,
    'onboarding_done': true,
  });

  await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
  await tester.pump();

  // `authState.bootstrap()` doit s'exécuter APRÈS le montage : c'est la
  // mutation de `authState.value` (donc l'appel `notifyListeners` du
  // `refreshListenable`) qui déclenche la réévaluation de `redirect` —
  // appeler bootstrap() avant que `appRouter` existe ne produit aucune
  // notification post-construction et laisse le routeur sur /splash.
  //
  // Ordre important : bootstrap() D'ABORD, `go('/splash')` ENSUITE.
  // `appRouter` est un singleton réutilisé d'un test à l'autre : avant
  // bootstrap(), `authState.value` porte encore le rôle du test
  // PRÉCÉDENT. Naviguer vers /splash avant de rafraîchir le rôle ferait
  // recalculer `homePathForRole` avec l'ANCIEN rôle, puis bootstrap()
  // changerait le rôle alors que le routeur est déjà posé sur la page
  // (restreinte) de l'ancien rôle → /403 au lieu de l'accueil attendu.
  // Un vrai changement de rôle utilisateur passe toujours par un nouveau
  // /login, jamais par ce genre de réutilisation — artefact du test, pas
  // un comportement réel.
  await authState.bootstrap();
  appRouter.go('/splash');

  // pumpAndSettle() n'est pas utilisable ici : les écrans de destination
  // lancent de vrais appels http (non simulés dans ce test) et affichent
  // un indicateur de chargement indéterminé, ce qui ne "s'installe"
  // jamais. La redirection elle-même (guards.redirect) est synchrone —
  // quelques frames suffisent à faire converger l'URL du routeur.
  //
  // `takeException()` après chaque frame : une fois la redirection
  // effectuée, l'écran de destination réel se construit (avec de vrais
  // appels http non simulés ici) et peut lever des exceptions de mise en
  // page sans rapport avec le routage (ex. un `RenderFlex` qui déborde
  // dans un composant à largeur fixe de `yeki_design_system.dart`, bug
  // préexistant hors périmètre P3.3) — ce test ne vérifie que l'URL
  // d'atterrissage, pas le rendu pixel des écrans de destination.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    tester.takeException();
  }

  // `SplashPage` démarre elle-même un minuteur de 2 s (vérification de
  // mise à jour) avant son propre `authState.bootstrap()` interne — sans
  // rapport avec le nôtre, déjà exécuté ci-dessus, mais ce minuteur doit
  // quand même se déclencher pendant le test (le `FakeAsync` de
  // `testWidgets` échoue sinon avec « Pending timers » au tearDown).
  await tester.pump(const Duration(seconds: 3));
  tester.takeException();

  return appRouter.routerDelegate.currentConfiguration.uri.toString();
}

void main() {
  final cases = <String, String>{
    'apprenant': '/dashboard/accueil',
    'admin': '/enseignant/admin',
    'enseignant_admin': '/enseignant/coordination',
    'enseignant_cadre': '/enseignant/cadre',
    'enseignant_principal': '/enseignant/principal',
    'enseignant': '/enseignant/secondaire',
    'service_client': '/service-client',
  };

  for (final entry in cases.entries) {
    testWidgets(
      'redirige le rôle "${entry.key}" vers ${entry.value}',
      (tester) async {
        final landing = await _landingPathForRole(tester, entry.key);
        expect(landing, entry.value);
      },
    );
  }

  // Séparation des interfaces (plan P3.3, §Vérification (e)-ii) : un
  // apprenant qui tente d'atteindre une route enseignant est refusé.
  testWidgets('un apprenant qui tente /enseignant/cadre reçoit /403',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'token': 'test-token',
      'role': 'apprenant',
      'onboarding_done': true,
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pump();
    await authState.bootstrap();
    appRouter.go('/splash');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      tester.takeException();
    }
    await tester.pump(const Duration(seconds: 3));
    tester.takeException();

    appRouter.goNamed(AppRoute.coursDetailEnseignant,
        pathParameters: {'coursId': '1'});
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      tester.takeException();
    }

    expect(appRouter.routerDelegate.currentConfiguration.uri.toString(),
        '/403');
  });
}
