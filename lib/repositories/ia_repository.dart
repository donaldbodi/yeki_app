import 'package:dio/dio.dart';

import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Yéki IA. Exemple canonique de l'override de timeout à 60s : les
/// appels LLM sont plus lents que le reste de l'API et ne doivent
/// JAMAIS toucher aux timeouts globaux (10s connexion / 30s réception)
/// utilisés par tous les autres appels.
class IaRepository {
  final ApiClient _api;

  IaRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> chat(int coursId, String message) async {
    final data = await _api.post(
      IaEndpoints.iaCoursChat(coursId),
      data: {'message': message},
      options: Options(
        receiveTimeout: ApiClient.iaTimeout,
        sendTimeout: ApiClient.iaTimeout,
      ),
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
