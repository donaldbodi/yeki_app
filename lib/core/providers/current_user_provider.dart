// lib/core/providers/current_user_provider.dart
//
// Provider transverse (P11.1) : profil de l'utilisateur connecté, sur le
// même patron que `notifications_provider.dart` — évite que chaque coquille
// de rôle (`ApprenantShellPage`, futurs équivalents) refasse son propre
// appel `GET /profil/me/` juste pour afficher nom/rôle dans la navigation.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/models/user_profile.dart';
import 'package:yeki/repositories/auth_repository.dart';

class CurrentUserController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => AuthRepository().getCurrentUser();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => AuthRepository().getCurrentUser());
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUserController, UserProfile>(
  CurrentUserController.new,
);
