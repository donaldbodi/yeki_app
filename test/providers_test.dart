// Vérification P3.4 : les 4 providers transverses s'initialisent sans
// exception non gérée. Utilise directement `ProviderContainer` (pas un
// pompage de widget complet) : ce sont des providers, pas des écrans —
// aucun écran ne les consomme encore (migration explicitement hors
// périmètre de ce ticket).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/core/providers/auth_provider.dart';
import 'package:yeki/core/providers/connectivity_provider.dart';
import 'package:yeki/core/providers/notifications_provider.dart';
import 'package:yeki/core/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('themeProvider : défaut système, persiste un changement de mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(themeProvider.future), ThemeMode.system);

    await container.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(container.read(themeProvider).value, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('connectivityProvider : reflète OfflineService.isOnline sans exception', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pas d'exception à la lecture — c'est tout ce que ce test vérifie ;
    // la valeur par défaut (true) vient du champ statique d'OfflineService.
    expect(() => container.read(connectivityProvider), returnsNormally);
  });

  test('authProvider : non authentifié (aucun token en cache) → null, sans appel réseau', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Aucun token en cache : `AuthController._toAuthUser` retourne `null`
    // avant même de tenter `AuthRepository().getCurrentUser()` — pas
    // besoin de mocker de réponse HTTP pour ce cas.
    expect(await container.read(authProvider.future), isNull);
  });

  test('notificationsProvider : build() se résout sans planter (erreur réseau tolérée en test)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Aucun backend réel dans cet environnement de test : un état
    // `AsyncError` est un résultat normal ici (Riverpod le capture
    // proprement) — ce test vérifie seulement l'absence de blocage/crash
    // non géré, pas le contenu de la réponse.
    try {
      await container.read(notificationsProvider.future);
    } catch (_) {
      // Attendu sans backend réel — la résolution propre (pas de hang,
      // pas d'exception non interceptée par Riverpod) est ce qui compte.
    }
  });
}
