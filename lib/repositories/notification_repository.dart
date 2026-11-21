import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/notification_models.dart';

/// Notifications in-app + jetons d'appareil (push FCM, P10.3/P10.4).
class NotificationRepository {
  final ApiClient _api;

  NotificationRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<AppNotification>> list() async {
    final data = await _api.get(NotificationsEndpoints.notifications);
    final results = data is List ? data : (data['results'] as List? ?? []);
    return results
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// `PATCH` — la vue backend (`MarquerNotificationLueView`) n'accepte que
  /// ce verbe (un `POST` renvoie 405).
  Future<void> markRead(int id) async {
    await _api.patch(NotificationsEndpoints.notificationsLire(id));
  }

  Future<void> markAllRead() async {
    await _api.post(NotificationsEndpoints.notificationsToutLire);
  }

  Future<int> unreadCount() async {
    final data = await _api.get(NotificationsEndpoints.notificationsNonLues);
    return (data['non_lues'] as num?)?.toInt() ?? 0;
  }

  /// Enregistre/actualise le jeton FCM de l'appareil courant.
  Future<void> enregistrerDeviceToken(String token, String plateforme) async {
    await _api.post(
      NotificationsEndpoints.notificationsDeviceToken,
      data: {'token': token, 'plateforme': plateforme},
    );
  }

  /// À appeler À LA DÉCONNEXION — obligatoire, sinon le prochain
  /// utilisateur de l'appareil reçoit les notifications du précédent.
  Future<void> supprimerDeviceToken(String token) async {
    await _api.delete(NotificationsEndpoints.notificationsDeviceTokenDetail(token));
  }
}
