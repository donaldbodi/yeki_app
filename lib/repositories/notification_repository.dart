import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Notifications. Chemin neuf, volontairement PAS branché sur
/// `lib/services/notification_service.dart` (hors périmètre de
/// migration explicite de cette tâche — seuls cache_manager,
/// offline_service et sync_service sont migrés maintenant). Ce
/// repository n'est adopté que par les futures migrations d'écran.
class NotificationRepository {
  final ApiClient _api;

  NotificationRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> list() async {
    final data = await _api.get(NotificationsEndpoints.notifications);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> markRead(int id) async {
    await _api.post(NotificationsEndpoints.notificationsLire(id));
  }

  Future<int> unreadCount() async {
    final data = await _api.get(NotificationsEndpoints.notificationsNonLues);
    return (data['non_lues'] as num?)?.toInt() ?? 0;
  }
}
