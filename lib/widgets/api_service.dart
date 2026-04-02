import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://yeki.pythonanywhere.com/api";

  static Future<List<dynamic>> getParcours() async {
    final res = await http.get(Uri.parse("$baseUrl/parcours/"));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Échec du chargement des parcours");
    }
  }

  static Future<List<dynamic>> getEnseignants() async {
    final res = await http.get(Uri.parse("$baseUrl/enseignants/"));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Échec du chargement des enseignants");
    }
  }

  static Future<Map<String, dynamic>> getStatistiquesGlobales() async {
    final res = await http.get(Uri.parse("$baseUrl/statistiques-globales/"));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Échec du chargement des statistiques");
    }
  }

  static Future<bool> changerAdmin(int parcoursId, int enseignantId) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/parcours/$parcoursId/changer-admin/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"enseignant_id": enseignantId}),
    );
    return res.statusCode == 200;
  }
}
