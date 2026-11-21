// lib/models/notification_models.dart
//
// Modèle notifications (P10.4) — `GET /api/notifications/`
// (`apps/notifications/serializers.py::NotificationSerializer`). Nommé
// `AppNotification` (pas `Notification`) pour ne pas entrer en collision
// avec la classe `Notification` de Flutter (`NotificationListener`).

/// Les 8 valeurs de `Notification.type` côté backend
/// (`apps/notifications/models.py`).
enum AppNotificationType { devoir, correction, olympiade, rappel, classement, forum, system, paiement }

AppNotificationType _typeDepuisString(String? valeur) {
  return AppNotificationType.values.firstWhere(
    (t) => t.name == valeur,
    orElse: () => AppNotificationType.system,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.estLue,
    required this.creeLe,
    required this.actionRoute,
  });

  final int id;
  final AppNotificationType type;
  final String titre;
  final String contenu;
  final bool estLue;
  final DateTime creeLe;

  /// Chemin go_router déjà résolu (IDs réels substitués) — navigable via
  /// `context.go(actionRoute)`. Vide si aucune action de redirection.
  final String actionRoute;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as int? ?? 0,
    type: _typeDepuisString(json['type'] as String?),
    titre: json['titre'] as String? ?? '',
    contenu: json['contenu'] as String? ?? '',
    estLue: json['est_lue'] as bool? ?? false,
    creeLe: DateTime.tryParse(json['cree_le'] as String? ?? '') ?? DateTime.now(),
    actionRoute: json['action_route'] as String? ?? '',
  );
}
