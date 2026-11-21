import 'package:flutter/foundation.dart';

import 'package:yeki/models/notification_models.dart';
import 'package:yeki/repositories/notification_repository.dart';

/// Filtre appliqué à la liste — `null` = toutes.
enum NotificationsFiltre { toutes, nonLues, parType }

class NotificationsController extends ChangeNotifier {
  NotificationsController({NotificationRepository? repository})
      : _repo = repository ?? NotificationRepository();

  final NotificationRepository _repo;

  bool chargement = true;
  bool enErreur = false;
  List<AppNotification> notifications = const [];

  NotificationsFiltre filtre = NotificationsFiltre.toutes;
  AppNotificationType? typeFiltre;

  int get nonLuesCount => notifications.where((n) => !n.estLue).length;

  List<AppNotification> get filtrees {
    switch (filtre) {
      case NotificationsFiltre.toutes:
        return notifications;
      case NotificationsFiltre.nonLues:
        return notifications.where((n) => !n.estLue).toList();
      case NotificationsFiltre.parType:
        return notifications.where((n) => n.type == typeFiltre).toList();
    }
  }

  Future<void> charger() async {
    chargement = true;
    enErreur = false;
    notifyListeners();
    try {
      notifications = await _repo.list();
    } catch (_) {
      enErreur = true;
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  void filtrerToutes() {
    filtre = NotificationsFiltre.toutes;
    notifyListeners();
  }

  void filtrerNonLues() {
    filtre = NotificationsFiltre.nonLues;
    notifyListeners();
  }

  void filtrerParType(AppNotificationType type) {
    filtre = NotificationsFiltre.parType;
    typeFiltre = type;
    notifyListeners();
  }

  Future<void> marquerLue(int id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].estLue) return;
    final ancienne = notifications[index];
    final mises = List<AppNotification>.from(notifications);
    mises[index] = AppNotification(
      id: ancienne.id,
      type: ancienne.type,
      titre: ancienne.titre,
      contenu: ancienne.contenu,
      estLue: true,
      creeLe: ancienne.creeLe,
      actionRoute: ancienne.actionRoute,
    );
    notifications = mises;
    notifyListeners();
    try {
      await _repo.markRead(id);
    } catch (_) {
      // Best-effort : l'état local reste "lue" (déjà vu par l'utilisateur
      // au moment du tap) — un échec réseau ponctuel n'a pas besoin de
      // rétablir un badge non-lu déroutant.
    }
  }

  Future<void> marquerToutesLues() async {
    notifications = notifications
        .map(
          (n) => AppNotification(
            id: n.id,
            type: n.type,
            titre: n.titre,
            contenu: n.contenu,
            estLue: true,
            creeLe: n.creeLe,
            actionRoute: n.actionRoute,
          ),
        )
        .toList();
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }
}
