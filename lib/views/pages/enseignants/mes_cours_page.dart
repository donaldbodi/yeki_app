import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'detail_cours_enseignant.dart';

class MesCoursPage extends StatefulWidget {
  final RoleEnseignant role;

  const MesCoursPage({super.key, required this.role});

  @override
  State<MesCoursPage> createState() => _MesCoursPageState();
}

class _MesCoursPageState extends State<MesCoursPage> {
  // ✅ Harmonisation des couleurs avec le Dashboard
  final Color primaryColor = const Color(0xFF2884A0);
  final Color bgLight = const Color(0xFFF1F5F9);
  final Color surfaceColor = Colors.white;
  final Color textDark = const Color(0xFF1E293B);

  List<Map<String, dynamic>> coursFiltres = [];
  List<Map<String, dynamic>> parcours = [];
  String? niveauFiltre;
  String? parcoursFiltre;

  final String baseUrl = "https://yekiapp.pythonanywhere.com/api";

  @override
  void initState() {
    super.initState();
    _fetchCours();
  }

  // --- LOGIQUE API ---

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
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
        if (data is Map && data.containsKey('cours')) {
          rawCours = data['cours'] ?? [];
        } else if (data is List) {
          rawCours = data;
        }
        setState(() {
          coursFiltres = rawCours
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Exception fetch cours: $e");
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final coursAffiches = coursFiltres.where((cours) {
      final filtreNiveau = niveauFiltre == null || (cours['niveau']?.toString() == niveauFiltre);
      final filtreParcours = parcoursFiltre == null || (cours['parcours']?.toString() == parcoursFiltre);
      return filtreNiveau && filtreParcours;
    }).toList();
/*IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCours),*/
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          _buildFiltresHeader(), // Barre de filtres stylisée
          Expanded(
            child: coursAffiches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: coursAffiches.length,
                    itemBuilder: (context, index) => _buildCarteCoursModern(coursAffiches[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFabSelonRole(widget.role),
    );
  }

  // --- COMPOSANTS STYLISÉS ---

  Widget _buildFiltresHeader() {
    final niveaux = coursFiltres.map((c) => c['niveau']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
    final listParcours = coursFiltres.map((c) => c['parcours']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();

    return Container(
      color: primaryColor,
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: _customDropdown(
              value: parcoursFiltre,
              hint: "Parcours",
              items: listParcours,
              onChanged: (val) => setState(() => parcoursFiltre = val),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _customDropdown(
              value: niveauFiltre,
              hint: "Niveau",
              items: niveaux,
              onChanged: (val) => setState(() => niveauFiltre = val),
            ),
          ),
          if (parcoursFiltre != null || niveauFiltre != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                parcoursFiltre = null;
                niveauFiltre = null;
              }),
            )
        ],
      ),
    );
  }

  Widget _customDropdown({String? value, required String hint, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          dropdownColor: primaryColor,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCarteCoursModern(Map<String, dynamic> cours) {
  final int leconsCount = _computeLeconsCount(cours);
  final int nbApprenants = _safeInt(cours['nb_apprenants'] ?? cours['nbApprenants']);
  final String titre = cours['titre'] ?? "Cours sans titre";
  final String parcoursNom = cours['parcours'] ?? "Général";

  // Détermination d'une couleur d'accent selon le parcours pour varier le design
  Color accentColor = primaryColor;
  if (parcoursNom.contains("Prépas")) accentColor = Colors.orange;
  if (parcoursNom.contains("Supérieur")) accentColor = Colors.purple;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: textDark.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailCoursEnseignantPage(
                coursId: cours['id'].toString(),
                role: widget.role,
                titre: cours['titre'] ?? "Cours",
                estEnseignantPrincipal: widget.role == RoleEnseignant.enseignantPrincipal,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            // Petit design en arrière-plan (cercle décoratif)
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 50,
                // ignore: deprecated_member_use
                backgroundColor: accentColor.withOpacity(0.05),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône de cours stylisée
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.menu_book_rounded, color: accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      
                      // Titre et Sous-titre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parcoursNom,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description avec un style plus léger
                  Text(
                    cours['description'] ?? "Accédez au contenu complet de ce module...",
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.blueGrey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Section Stats / Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badgeIcon(Icons.person_search_rounded, "$nbApprenants"),
                      _badgeIcon(Icons.play_circle_filled_rounded, "$leconsCount Leçons"),
                      
                      // Bouton d'action minimaliste
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: textDark,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Text("Détails", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Widget utilitaire pour les mini-stats en bas de carte
Widget _badgeIcon(IconData icon, String label) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[400]),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucun cours trouvé", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget? _buildFabSelonRole(RoleEnseignant role) {
    if (role == RoleEnseignant.enseignantCadre) {
      return FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouveau Cours", style: TextStyle(color: Colors.white)),
        onPressed: _creerCours,
      );
    }
    return null;
  }

  // --- LOGIQUE DE SUPPORT ---

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  int _computeLeconsCount(Map<String, dynamic> c) {
    if (c.containsKey('lecons_count')) return _safeInt(c['lecons_count']);
    if (c['lecons'] is List) return (c['lecons'] as List).length;
    return 0;
  }

  Future<void> _creerCours() async {
    final titreCtrl = TextEditingController();
    final niveauCtrl = TextEditingController();

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
}