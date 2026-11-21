// Vérifie le bug corrigé (Phase 2) : la déconnexion ne redirigeait jamais
// vers /login. Cause racine : `clearSession()` appelait `value.copyWith(
// token: null, role: null)` — `copyWith` utilise le motif `param ??
// this.field`, qui ne peut pas distinguer « non fourni » de « remise à
// null volontaire » : `null ?? this.token` renvoyait l'ANCIEN token,
// jamais effacé de `authState.value` malgré le stockage bien vidé.
// `snapshot.isAuthenticated` restait donc `true` pour toujours, empêchant
// `guards.dart` de détecter la déconnexion et de rediriger.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/router/auth_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clearSession() efface bien token/role de authState.value (bug corrigé)', () async {
    authState.value = const YekiAuthSnapshot(
      bootstrapped: true,
      token: 'un-vrai-jeton',
      role: 'apprenant',
      onboardingDone: true,
    );
    expect(authState.value.isAuthenticated, isTrue);

    await authState.clearSession();

    expect(authState.value.isAuthenticated, isFalse, reason: 'régression du bug : token jamais effacé');
    expect(authState.value.token, isNull);
    expect(authState.value.role, isNull);
    expect(authState.value.bootstrapped, isTrue);
    // `onboardingDone` est un indicateur au niveau de l'appareil, pas de
    // la session — doit être préservé, pas réinitialisé à la déconnexion.
    expect(authState.value.onboardingDone, isTrue);
  });

  test('logout() (API + nettoyage local) produit le même résultat que clearSession()', () async {
    authState.value = const YekiAuthSnapshot(
      bootstrapped: true,
      token: 'un-autre-jeton',
      role: 'enseignant_cadre',
      onboardingDone: true,
    );

    // `AuthRepository().logout()` échouera (pas de vrai réseau en test) —
    // `logout()` doit rattraper cette erreur et effacer la session locale
    // quand même (comportement déjà voulu, pas modifié par ce correctif).
    await authState.logout();

    expect(authState.value.isAuthenticated, isFalse);
    expect(authState.value.token, isNull);
    expect(authState.value.role, isNull);
  });
}
