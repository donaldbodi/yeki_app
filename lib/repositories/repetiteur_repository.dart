import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Répétiteurs. Tranche initiale : recherche seulement.
class RepetiteurRepository {
  final ApiClient _api;

  RepetiteurRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> search(Map<String, dynamic> filters) async {
    final data = await _api.get(
      RepetiteursEndpoints.repetiteursSearch,
      query: filters,
    );
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
