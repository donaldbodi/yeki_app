import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'ajout_enseignant_page.dart';
import 'detail_cours_enseignant.dart';

class MesCoursPage extends StatefulWidget {
  final RoleEnseignant role;

  const MesCoursPage({super.key, required this.role});

  @override
  State<MesCoursPage> createState() => _MesCoursPageState();
}

class _MesCoursPageState extends State<MesCoursPage> {
  List<Map<String, dynamic>> coursFiltres = [];
  List<Map<String, dynamic>> parcours = [];
  String? niveauFiltre;
  String? parcoursFiltre;

  final String baseUrl = "https://yekiapp.pythonanywhere.com/api";

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchCours();
  }

  Future<void> _fetchCours() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/enseignant/dashboard/"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> rawCours = [];
        List<dynamic> rawParcours = [];
        if (data is Map && data.containsKey('cours')) {
          rawCours = data['cours'] ?? [];
        } else if (data.containsKey('parcours')) {
          rawParcours = data['parcours'] ?? [];
        } else if (data is List) {
          rawCours = data;
        }
        setState(() {
          coursFiltres = rawCours
              .where((e) => e is Map)
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              )
              .toList();
          parcours = rawParcours.where((e) => e is Map)
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
              )
              .toList();
        });
      } else {
        debugPrint(
          "Erreur fetch cours: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Exception fetch cours: $e");
    }
  }

  // ======= CREER COURS (pour enseignant cadre) =======
  Future<void> _creerCours() async {
    final titreCtrl = TextEditingController();
    final niveauCtrl = TextEditingController();
    int? departementId;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Créer un cours"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreCtrl,
              decoration: const InputDecoration(labelText: "Titre du cours"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: niveauCtrl,
              decoration: const InputDecoration(
                labelText: "Niveau (optionnel)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final titre = titreCtrl.text.trim();
              final niveau = niveauCtrl.text.trim();
              if (titre.isEmpty) return;
              final headers = await _authHeaders();
              final body = {
                'titre': titre,
                if (niveau.isNotEmpty) 'niveau': niveau,
                if (departementId != null) 'departement': departementId,
              };
              final res = await http.post(
                Uri.parse("$baseUrl/cours/"),
                headers: headers,
                body: jsonEncode(body),
              );
              if (res.statusCode == 201 || res.statusCode == 200) {
                Navigator.pop(context);
                await _fetchCours();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cours créé.')));
              } else {
                debugPrint(
                  "Erreur création cours: ${res.statusCode} ${res.body}",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur création (${res.statusCode})'),
                  ),
                );
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  String _safeTitle(Map<String, dynamic> m) {
    return (m['titre'] ?? m['nom'] ?? '').toString();
  }

  String _safeDescription(Map<String, dynamic> m) {
    return (m['description'] ?? m['desc'] ?? '').toString();
  }

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _computeLeconsCount(Map<String, dynamic> c) {
    if (c.containsKey('lecons_count')) return _safeInt(c['lecons_count']);
    if (c.containsKey('lecons') && c['lecons'] is List)
      return (c['lecons'] as List).length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final coursAffiches = coursFiltres.where((cours) {
      final filtreNiveau =
          niveauFiltre == null || (cours['niveau']?.toString() == niveauFiltre);
      final filtreParcours =
          parcoursFiltre == null ||
          (cours['parcours']?.toString() == parcoursFiltre);
      return filtreNiveau && filtreParcours;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mes Cours",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCours),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            _buildFiltres(),
            Expanded(
              child: ListView.builder(
                itemCount: coursAffiches.length,
                itemBuilder: (context, index) {
                  final cours = coursAffiches[index];
                  return _buildCarteCours(cours);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFabSelonRole(widget.role),
    );
  }

  Widget _buildFiltres() {
    final niveaux = coursFiltres
        .map((c) => (c['niveau']?.toString() ?? ''))
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final parcours = coursFiltres
        .map((c) => (c['parcours']?.toString() ?? ''))
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          DropdownButton<String>(
            value: parcoursFiltre,
            hint: const Text("Filtrer par parcours"),
            items: parcours
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => parcoursFiltre = val),
          ),
          DropdownButton<String>(
            value: niveauFiltre,
            hint: const Text("Filtrer par niveau"),
            items: niveaux
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => niveauFiltre = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteCours(Map<String, dynamic> cours) {
    final title = _safeTitle(cours);
    final description = _safeDescription(cours);
    final leconsCount = _computeLeconsCount(cours);
    final nbApprenants = _safeInt(
      cours['nb_apprenants'] ?? cours['nbApprenants'],
    );
    final nbEnseignants = _safeInt(
      cours['nb_enseignants'] ?? cours['nbEnseignants'],
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailCoursEnseignantPage(
              cours: cours,
              estEnseignantPrincipal:
                  widget.role == RoleEnseignant.enseignantPrincipal,
            ),
          ),
        );
      },
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF03224C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description.isEmpty ? "Aucune description" : description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoIcon(
                    Icons.school,
                    "Parcours : ${cours['parcours'] ?? '-'}",
                  ),
                  _buildInfoIcon(
                    Icons.grade,
                    "Niveau : ${cours['niveau'] ?? '-'}",
                  ),
                  _buildInfoIcon(Icons.category, _getLabelCours(cours)),
                  _buildInfoIcon(Icons.menu_book, "$leconsCount leçons"),
                  _buildInfoIcon(Icons.people, "$nbApprenants apprenants"),
                  _buildInfoIcon(Icons.person, "$nbEnseignants enseignants"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.teal.shade700),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget? _buildFabSelonRole(RoleEnseignant role) {
    if (role == RoleEnseignant.enseignantCadre) {
      return FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Créer un cours"),
        onPressed: _creerCours,
      );
    }
    return null; // ✅ la création de leçon sera gérée ailleurs
  }

  String _getLabelCours(Map<String, dynamic> cours) {
    final parcours = (cours['parcours'] ?? '').toString();
    final field =
        cours['matiere'] ??
        cours['concours'] ??
        cours['departement'] ??
        cours['matiereOuConcoursOuDepartement'];
    final value = field?.toString() ?? '';
    if (parcours == "Prépas") return "Concours : $value";
    if (parcours == "Supérieur") return "Département : $value";
    return "Matière : $value";
  }
}
