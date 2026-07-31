import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Une entrée d'activité enseignant (`historique_page.dart`, P11.8) —
/// jamais consommé via un repository avant ce ticket.
class ActiviteHistorique {
  const ActiviteHistorique({
    required this.action,
    required this.label,
    required this.description,
    required this.timestamp,
    required this.data,
  });

  final String action;
  final String label;
  final String description;
  final DateTime? timestamp;
  final Map<String, dynamic> data;

  factory ActiviteHistorique.fromJson(Map<String, dynamic> json) => ActiviteHistorique(
    action: json['action']?.toString() ?? '',
    label: json['action_label']?.toString() ?? json['action']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
    data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
  );
}

class HistoriqueRepository {
  final ApiClient _api;

  HistoriqueRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ActiviteHistorique>> activites({String? categorie, DateTime? depuis, int limit = 200}) async {
    final data = await _api.get(
      CoreEndpoints.historique,
      query: {
        if (categorie != null && categorie.isNotEmpty) 'category': categorie,
        if (depuis != null) 'depuis': depuis.toIso8601String().split('T').first,
        'limit': limit.toString(),
      },
    );
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => ActiviteHistorique.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Map<String, dynamic>> stats() async {
    final data = await _api.get(CoreEndpoints.historiqueStats);
    return Map<String, dynamic>.from(data as Map);
  }
}
