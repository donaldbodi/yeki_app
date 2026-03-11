import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPrincipalPage extends StatefulWidget {
  final String nomEnseignant;
  final String roleEnseignant;
  final List<dynamic>? extraInfo;

  const DashboardPrincipalPage({
    super.key,
    required this.nomEnseignant,
    required this.roleEnseignant,
    this.extraInfo,
  });

  @override
  State<DashboardPrincipalPage> createState() => _DashboardPrincipalPageState();
}

class _DashboardPrincipalPageState extends State<DashboardPrincipalPage> {
  static const String baseUrl = 'https://yekiapp.pythonanywhere.com';
  
  final Color primaryColor = const Color(0xFF2884A0);
  final Color bgLight = const Color(0xFFF1F5F9);
  final Color surfaceColor = Colors.white;
  final Color textDark = const Color(0xFF1E293B);

  late List<dynamic> _localExtraInfo;
  List<Map<String, dynamic>> _enseignantsSecondaires = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localExtraInfo = List<dynamic>.from(widget.extraInfo ?? const []);
    _fetchEnseignantsSecondaires();
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

  List<Map<String, dynamic>> _asListOfMap(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw.where((e) => e is Map).map<Map<String, dynamic>>(
      (e) => Map<String, dynamic>.from((e as Map).map((k, v) => MapEntry(k.toString(), v))),
    ).toList();
  }

  Future<void> _fetchEnseignantsSecondaires() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/api/enseignants_secondaires/'), headers: headers);
      if (res.statusCode == 200) {
        setState(() {
          _enseignantsSecondaires = _asListOfMap(jsonDecode(res.body));
        });
      }
    } catch (_) {}
  }

  // --- NOUVELLE LOGIQUE D'AJOUT MULTIPLE ---

  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    // Liste des IDs sélectionnés localement dans le modal
    List<int> selectedIds = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder( // Important pour mettre à jour l'état interne du modal
          builder: (BuildContext context, StateSetter setModalState) {
            final coursList = _asListOfMap(_localExtraInfo);
            final cours = coursList.firstWhere((c) => c['id'] == coursId, orElse: () => {});
            final existants = _asListOfMap((cours['enseignants_secondaires'] as List?) ?? []);
            final existantsIds = existants.map((e) => e['id']).toSet();
            
            // On ne montre que ceux qui ne sont pas encore dans le cours
            final candidats = _enseignantsSecondaires.where((e) => !existantsIds.contains(e['id'])).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(color: bgLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text('Assigner des assistants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  Text('${candidats.length} enseignants disponibles', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: candidats.isEmpty 
                      ? const Center(child: Text("Tous les enseignants sont déjà assignés."))
                      : ListView.builder(
                          itemCount: candidats.length,
                          itemBuilder: (context, index) {
                            final ens = candidats[index];
                            final isSelected = selectedIds.contains(ens['id']);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(15)),
                              child: CheckboxListTile(
                                activeColor: primaryColor,
                                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                title: Text(ens['user']['username'] ?? 'Sans nom', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(ens['specialite'] ?? 'Enseignant secondaire', style: const TextStyle(fontSize: 11)),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedIds.add(ens['id']);
                                    } else {
                                      selectedIds.remove(ens['id']);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: selectedIds.isEmpty || _isLoading ? null : () async {
                        setModalState(() => _isLoading = true);
                        
                        final headers = await _authHeaders();
                        bool success = true;

                        // On boucle pour ajouter chaque enseignant sélectionné
                        for (int id in selectedIds) {
                          final res = await http.post(
                            Uri.parse('$baseUrl/api/cours/$coursId/add-enseignant/'),
                            headers: headers,
                            body: jsonEncode({'enseignant_id': id}),
                          );
                          if (res.statusCode != 201 && res.statusCode != 200) {
                            success = false;
                          }
                        }

                        if (success) {
                          // Mise à jour de l'UI principale
                          setState(() {
                            for (var c in _localExtraInfo) {
                              if (c['id'] == coursId) {
                                List sec = List.from(c['enseignants_secondaires'] ?? []);
                                for (int id in selectedIds) {
                                  var added = _enseignantsSecondaires.firstWhere((e) => e['id'] == id);
                                  sec.add(added);
                                }
                                c['enseignants_secondaires'] = sec;
                              }
                            }
                          });
                        }

                        setModalState(() => _isLoading = false);
                        if (mounted) Navigator.pop(context);
                      },
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Ajouter ${selectedIds.length} sélection(s)'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _retirerEnseignantSecondaire(int coursId, int enseignantId) async {
    final headers = await _authHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/api/cours/$coursId/enseignants-secondaires/$enseignantId/'), headers: headers);
    if (res.statusCode == 204 || res.statusCode == 200) {
      setState(() {
        for (var c in _localExtraInfo) {
          if (c['id'] == coursId) {
            List sec = List.from(c['enseignants_secondaires'] ?? []);
            sec.removeWhere((e) => (e is Map ? e['id'] : e) == enseignantId);
            c['enseignants_secondaires'] = sec;
          }
        }
      });
    }
  }

  // --- RESTE DU CODE UI (Identique à ton message) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPISection(),
            const SizedBox(height: 30),
            _buildSectionTitle("Suivi des Devoirs & Rendus"),
            const SizedBox(height: 15),
            _buildHomeworkAnalytics(),
            const SizedBox(height: 30),
            _buildSectionTitle("Élèves à surveiller"),
            const SizedBox(height: 15),
            _buildAtRiskStudents(),
            const SizedBox(height: 30),
            _buildSectionTitle("Mes Cours & Équipe"),
            const SizedBox(height: 15),
            _buildCourseList(),
          ],
        ),
      ),
    );
  }


  Widget _buildKPISection() {
    return Row(
      children: [
        _statCard("Rendu", "88%", Icons.assignment_turned_in, Colors.green),
        const SizedBox(width: 12),
        _statCard("Moyenne", "14.2", Icons.analytics, primaryColor),
        const SizedBox(width: 12),
        _statCard("Retards", "05", Icons.timer_outlined, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _homeworkRow("Mathématiques : Matrices", 0.75, "22/30 élèves"),
          const Divider(height: 30),
          _homeworkRow("Physique : Dynamique", 0.40, "12/30 élèves"),
        ],
      ),
    );
  }

  Widget _homeworkRow(String title, double progress, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(detail, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: bgLight, color: progress > 0.5 ? primaryColor : Colors.orange),
        ),
      ],
    );
  }

  Widget _buildAtRiskStudents() {
    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _studentRiskTile("Awa Diop", "3 retards consécutifs", Colors.red),
          _studentRiskTile("Kevin N.", "Moyenne en baisse", Colors.orange),
        ],
      ),
    );
  }

  Widget _studentRiskTile(String name, String reason, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(reason, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
    );
  }

  Widget _buildCourseList() {
    return Column(children: _localExtraInfo.map((c) => _buildDetailedCourseCard(c)).toList());
  }

  Widget _buildDetailedCourseCard(Map<String, dynamic> c) {
    final assistants = _asListOfMap((c['enseignants_secondaires'] as List?) ?? []);
    final int lecons = c['nb_lecons'] ?? 0;
    final int devoirs = c['nb_devoirs'] ?? 0;
    final int exercices = c['exercices_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['titre'] ?? "Cours", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _badge(Icons.book, "$lecons Leçons", Colors.blue),
                    const SizedBox(width: 8),
                    _badge(Icons.assignment, "$devoirs Devoirs", Colors.orange),
                    const SizedBox(width: 8),
                    _badge(Icons.quiz, "$exercices Quiz", Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: Text("Équipe (${assistants.length})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            leading: Icon(Icons.people_outline, color: primaryColor, size: 20),
            children: [
              ...assistants.map((e) => ListTile(
                dense: true,
                title: Text(e['name'] ?? "Assistant"),
                trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18), onPressed: () => _retirerEnseignantSecondaire(c['id'], e['id'])),
              )),
              TextButton.icon(onPressed: () => _ajouterEnseignantSecondaire(c['id']), icon: const Icon(Icons.add, size: 16), label: const Text("Ajouter"), style: TextButton.styleFrom(foregroundColor: primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark));
  }
}