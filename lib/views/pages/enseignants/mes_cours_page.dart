// lib/views/pages/enseignants/mes_cours_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// MES COURS ENSEIGNANT — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/views/pages/enseignants/detail_cours_enseignant.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCours();
  }

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
        Uri.parse(ApiConstants.enseignantDashboard),
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

  @override
  Widget build(BuildContext context) {
    final coursAffiches = coursFiltres.where((cours) {
      final filtreNiveau = niveauFiltre == null || (cours['niveau']?.toString() == niveauFiltre);
      final filtreParcours = parcoursFiltre == null || (cours['parcours']?.toString() == parcoursFiltre);
      return filtreNiveau && filtreParcours;
    }).toList();

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mes Cours', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: YekiColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: YekiColors.borderLight),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: YekiColors.primaryDark),
            onPressed: _fetchCours,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltresHeader(),
          Expanded(
            child: coursAffiches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: coursAffiches.length,
                    itemBuilder: (context, index) => _buildCarteCoursModern(coursAffiches[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFabSelonRole(widget.role),
    );
  }

  Widget _buildFiltresHeader() {
    final niveaux = coursFiltres.map((c) => c['niveau']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
    final listParcours = coursFiltres.map((c) => c['parcours']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();

    return Container(
      color: YekiColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 12),
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
              icon: const Icon(Icons.close, color: YekiColors.textLight),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: YekiColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          dropdownColor: YekiColors.white,
          icon: Icon(Icons.keyboard_arrow_down, color: YekiColors.textLight),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(
            value: e, 
            child: Text(e, style: const TextStyle())
          )).toList(),
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

    Color accentColor = YekiColors.primaryDark;
    if (parcoursNom.contains("Prépas")) accentColor = YekiColors.accent;
    if (parcoursNom.contains("Supérieur")) accentColor = YekiColors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                  courseColor: accentColor,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.8),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: accentColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parcoursNom,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  cours['description'] ?? "Accédez au contenu complet de ce module...",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: YekiColors.borderLight, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _badgeIcon(Icons.person_outline_rounded, "$nbApprenants apprenants"),
                    _badgeIcon(Icons.play_lesson_rounded, "$leconsCount leçons"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text("Détails", style: TextStyle(color: YekiColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: YekiColors.white, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: YekiColors.textLight),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
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
          Icon(Icons.auto_stories, size: 64, color: YekiColors.borderLight),
          const SizedBox(height: 16),
          Text(
            "Aucun cours trouvé",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (widget.role == RoleEnseignant.enseignantCadre)
            YekiButton(
              label: "Créer un cours",
              icon: Icons.add,
              onPressed: _creerCours,
              width: 180,
            ),
        ],
      ),
    );
  }

  Widget? _buildFabSelonRole(RoleEnseignant role) {
    if (role == RoleEnseignant.enseignantCadre) {
      return FloatingActionButton.extended(
        backgroundColor: YekiColors.primaryDark,
        icon: const Icon(Icons.add, color: YekiColors.white),
        label: const Text("Nouveau Cours", style: TextStyle(color: YekiColors.white)),
        onPressed: _creerCours,
      );
    }
    return null;
  }

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
    final parcoursCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text("Créer un cours", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreCtrl,
              decoration: InputDecoration(
                labelText: "Titre du cours",
                labelStyle: const TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.primaryDark),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: niveauCtrl,
              decoration: InputDecoration(
                labelText: "Niveau (optionnel)",
                labelStyle: const TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.primaryDark),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: parcoursCtrl,
              decoration: InputDecoration(
                labelText: "Parcours (optionnel)",
                labelStyle: const TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.primaryDark),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              final titre = titreCtrl.text.trim();
              final niveau = niveauCtrl.text.trim();
              final parcours = parcoursCtrl.text.trim();
              if (titre.isEmpty) return;
              final headers = await _authHeaders();
              final body = {
                'titre': titre,
                if (niveau.isNotEmpty) 'niveau': niveau,
                if (parcours.isNotEmpty) 'parcours': parcours,
              };
              final res = await http.post(
                Uri.parse('${ApiConstants.baseUrl}/cours/'),
                headers: headers,
                body: jsonEncode(body),
              );
              if (res.statusCode == 201 || res.statusCode == 200) {
                if (context.mounted) Navigator.pop(context);
                await _fetchCours();
                ErrorHandler.showSuccess(context, 'Cours créé avec succès.');
              } else {
                ErrorHandler.showError(context, 'Erreur création (${res.statusCode})');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.primaryDark,
              foregroundColor: YekiColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }
}