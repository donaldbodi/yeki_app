// lib/core/providers/notifications_provider.dart
//
// Provider transverse (P3.4) : compteur de notifications non lues.
// Backé par `NotificationRepository.unreadCount()` (nouvelle méthode,
// appelle `GET /notifications/non-lues/` — endpoint déjà défini côté
// client mais jamais utilisé) plutôt que de dupliquer le recalcul local
// déjà fait dans `notifications_page.dart`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/repositories/notification_repository.dart';

class NotificationsController extends AsyncNotifier<int> {
  @override
  Future<int> build() => NotificationRepository().unreadCount();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => NotificationRepository().unreadCount());
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsController, int>(
  NotificationsController.new,
);
