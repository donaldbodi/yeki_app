import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show CoursItem;

/// Cours. Tranche initiale : lecture seule pour un département — le reste
/// (détail, modules, leçons, gestion enseignant) attend la migration de
/// son écran.
class CoursRepository {
  final ApiClient _api;

  CoursRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<CoursItem>> listForDepartement(int departementId) async {
    final data = await _api.get(FormationEndpoints.departementsCours(departementId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => CoursItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
