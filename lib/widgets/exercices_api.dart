import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExercicesApi {
  static const String baseUrl = "https://yeki.pythonanywhere.com/api";

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, dynamic>> demarrerExercice(int exerciceId) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse("$baseUrl/exercices/$exerciceId/demarrer/"),
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json"
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Impossible de démarrer l'exercice");
    }
  }

  static Future<Map<String, dynamic>> soumettre(
      int exerciceId, Map<String, String> reponses) async {
    final token = await _token();

    final res = await http.post(
      Uri.parse("$baseUrl/exercices/$exerciceId/evaluer/"),
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"reponses": reponses}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Erreur soumission examen");
    }
  }
}