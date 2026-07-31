import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData, MultipartFile;

import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Forum (P10.5 — étendu au-delà de la liste initiale : détail, réponses,
/// likes, résolution, sondage temps réel), consommé par `forum_page.dart`,
/// `details_question_forum.dart` et `form_preoccupation_sheet.dart`.
class ForumRepository {
  final ApiClient _api;

  ForumRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> listQuestions({String? source, int? coursId}) async {
    final query = <String, dynamic>{};
    if (source != null && source != 'tous') query['source'] = source;
    if (coursId != null) query['cours_id'] = coursId.toString();
    final data = await _api.get(ForumEndpoints.forumQuestions, query: query.isEmpty ? null : query);
    final list = data is List ? data : (data['results'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getQuestion(int id) async {
    final data = await _api.get(ForumEndpoints.forumQuestionsDetail(id));
    return Map<String, dynamic>.from(data as Map);
  }

  /// Sondage léger (`?since=`) — repli sans WebSocket (PythonAnywhere ne
  /// les supporte pas), voir `ApiConstants.forumRealtimeEnabled`.
  Future<Map<String, dynamic>> sonderActivite(String room, {DateTime? since}) async {
    final query = since != null ? {'since': since.toUtc().toIso8601String()} : null;
    final data = await _api.get(ForumEndpoints.forumMessages(room), query: query);
    return Map<String, dynamic>.from(data as Map);
  }

  /// Répond à une question. `imageBytes` optionnel (jamais `dart:io File` —
  /// portabilité web, voir `YkPickedFile`).
  Future<void> repondre({
    required int questionId,
    required String contenu,
    Uint8List? imageBytes,
    String? imageNom,
  }) async {
    final data = imageBytes != null
        ? FormData.fromMap({
            'contenu': contenu,
            'image': MultipartFile.fromBytes(imageBytes, filename: imageNom ?? 'image.jpg'),
          })
        : {'contenu': contenu};
    await _api.post(ForumEndpoints.forumQuestionsRepondre(questionId), data: data);
  }

  Future<Map<String, dynamic>> liker(int reponseId) async {
    final data = await _api.post(ForumEndpoints.forumReponsesLiker(reponseId));
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> marquerSolution(int reponseId) async {
    await _api.patch(ForumEndpoints.forumReponsesSolution(reponseId));
  }

  Future<void> resoudreQuestion(int questionId) async {
    await _api.patch(ForumEndpoints.forumQuestionsResoudre(questionId));
  }

  /// Crée une question et renvoie l'objet COMPLET tel que sérialisé par le
  /// backend (`QuestionForumListSerializer` — `id`, `cours_id`,
  /// `cours_titre`, etc.). L'appelant doit naviguer d'après CETTE réponse,
  /// jamais d'après les valeurs qu'il a lui-même envoyées (P10.5 : le
  /// backend fait autorité sur le `cours_id` réellement enregistré).
  Future<Map<String, dynamic>> creerQuestion({
    required String contenu,
    required String source,
    int? leconId,
    String? leconTitre,
    int? coursId,
    String? coursTitre,
    int? exerciceId,
    String? exerciceTitre,
    int? devoirId,
    String? devoirTitre,
    Uint8List? imageBytes,
    Uint8List? audioBytes,
  }) async {
    final champs = <String, dynamic>{'contenu': contenu, 'source': source};
    if (leconId != null) {
      champs['lecon_id'] = leconId;
      champs['lecon_titre'] = leconTitre ?? '';
    }
    if (coursId != null) {
      champs['cours_id'] = coursId;
      champs['cours_titre'] = coursTitre ?? '';
    }
    if (exerciceId != null) {
      champs['exercice_id'] = exerciceId;
      champs['exercice_titre'] = exerciceTitre ?? '';
    }
    if (devoirId != null) {
      champs['devoir_id'] = devoirId;
      champs['devoir_titre'] = devoirTitre ?? '';
    }
    final horodatage = DateTime.now().millisecondsSinceEpoch;
    final data = (imageBytes != null || audioBytes != null)
        ? await _api.post(
            ForumEndpoints.forumQuestions,
            data: FormData.fromMap({
              ...champs,
              if (imageBytes != null)
                'image': MultipartFile.fromBytes(imageBytes, filename: 'question_image_$horodatage.jpg'),
              if (audioBytes != null)
                'audio': MultipartFile.fromBytes(audioBytes, filename: 'question_audio_$horodatage.m4a'),
            }),
          )
        : await _api.post(ForumEndpoints.forumQuestions, data: champs);
    return Map<String, dynamic>.from(data as Map);
  }
}
