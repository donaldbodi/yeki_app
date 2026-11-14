import 'dart:typed_data';

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

  /// Envoie un message. Retourne l'enveloppe complète du backend (P10.1) :
  /// `{reponse, message_id, assistant_id, tokens_input, tokens_output,
  /// cout_xaf, solde_avant, solde_restant, debit_ok}` en succès. En échec,
  /// lève une `ApiException` (402 solde insuffisant avec
  /// `fields: {solde_actuel, minimum_requis, cout_estime_min,
  /// cout_estime_max}`, ou 503 échec Claude avec `fields: {solde_actuel}`
  /// — dans les deux cas AUCUN débit n'a eu lieu côté serveur).
  Future<Map<String, dynamic>> chat({
    required int coursId,
    required String message,
    String source = 'libre',
    int? sourceId,
    String sourceTitre = '',
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    final champs = <String, dynamic>{
      'message': message,
      'source': source,
      'source_id': ?sourceId,
      'source_titre': sourceTitre,
    };
    final horodatage = DateTime.now().millisecondsSinceEpoch;
    final body = (imageBytes != null || audioBytes != null)
        ? FormData.fromMap({
            ...champs,
            if (imageBytes != null)
              'image': MultipartFile.fromBytes(imageBytes, filename: 'ia_image_$horodatage.jpg'),
            if (audioBytes != null)
              'audio': MultipartFile.fromBytes(audioBytes, filename: 'ia_audio_$horodatage.m4a'),
          })
        : champs;
    final data = await _api.post(
      IaEndpoints.iaCoursChat(coursId),
      data: body,
      options: Options(receiveTimeout: ApiClient.iaTimeout, sendTimeout: ApiClient.iaTimeout),
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> historique(int coursId) async {
    final data = await _api.get(IaEndpoints.iaCoursHistorique(coursId));
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> effacerHistorique(int coursId) async {
    await _api.delete(IaEndpoints.iaCoursHistorique(coursId));
  }
}
