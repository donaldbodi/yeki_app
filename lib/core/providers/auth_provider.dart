// lib/core/providers/auth_provider.dart
//
// Provider transverse (P3.4) exposant l'état d'authentification côté
// Riverpod. Ne duplique PAS `authState` (lib/core/router/auth_state.dart) :
// ce dernier reste la seule source de vérité pour le routage
// (`GoRouter(refreshListenable: authState)` + `AuthInterceptor.
// onSessionExpired`, P3.3) — `authProvider` se contente de l'écouter et
// d'enrichir son état avec le profil complet (`AuthRepository.
// getCurrentUser()`, déjà existant). `login()`/`logout()` délèguent à
// `authState` : un seul mécanisme de mutation de session dans tout le
// projet.

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/core/providers/current_user_provider.dart';
import 'package:yeki/core/providers/notifications_provider.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/models/user_profile.dart';
import 'package:yeki/repositories/auth_repository.dart';

@immutable
class AuthUser {
  final String token;
  final String role;
  // Null tant que le fetch du profil complet n'a pas abouti — une session
  // reste valide même si ce fetch échoue (best-effort, voir _toAuthUser).
  final UserProfile? profile;

  const AuthUser({required this.token, required this.role, this.profile});
}

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    authState.addListener(_onAuthStateChanged);
    ref.onDispose(() => authState.removeListener(_onAuthStateChanged));
    return _toAuthUser(authState.value);
  }

  void _onAuthStateChanged() {
    state = const AsyncValue<AuthUser?>.loading();
    // Invalide les profils/compteurs mis en cache par compte — sans ça,
    // une bascule de compte en cours de session (déconnexion + reconnexion
    // avec un AUTRE compte) peut brièvement réafficher le nom/compteur de
    // l'ancien compte même une fois la bonne route chargée (bug corrigé,
    // contributeur secondaire de la bascule de rôle).
    ref.invalidate(currentUserProvider);
    ref.invalidate(notificationsProvider);
    _toAuthUser(authState.value).then((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<AuthUser?> _toAuthUser(YekiAuthSnapshot snapshot) async {
    if (!snapshot.isAuthenticated) return null;
    UserProfile? profile;
    try {
      profile = await AuthRepository().getCurrentUser();
    } catch (_) {
      // Best-effort : l'échec du fetch profil ne doit jamais invalider
      // une session par ailleurs valide (token/rôle déjà en cache).
    }
    return AuthUser(
      token: snapshot.token!,
      role: snapshot.role ?? '',
      profile: profile,
    );
  }

  Future<void> login({required String token, required String role}) =>
      authState.login(token: token, role: role);

  Future<void> logout() => authState.logout();
}

final authProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
