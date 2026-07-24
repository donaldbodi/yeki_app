import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Forum. Tranche initiale : liste des questions seulement (aucun modèle
/// Forum n'existe encore ailleurs dans le projet). Le reste (détail,
/// réponses, likes, temps réel — déjà signalé désactivé dans les
/// documents produit) attend la migration de son écran.
class ForumRepository {
  final ApiClient _api;

  ForumRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> listQuestions() async {
    final data = await _api.get(ForumEndpoints.forumQuestions);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
