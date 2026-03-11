import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:yeki/views/pages/apprenants/notifications_page.dart';
import 'package:yeki/views/pages/apprenants/profil_page.dart';

import '../../../../widgets/yeki_app_bar.dart';
import 'cours_detail_page.dart';
const String _base = 'https://yekiapp.pythonanywhere.com/api';

class CursusPage extends StatefulWidget {
  const CursusPage({super.key});

  @override
  State<CursusPage> createState() => _CursusPageState();
}

class _CursusPageState extends State<CursusPage> {
  // ✅ Identité Visuelle Yeki
  final Color mainBlue = const Color(0xFF2884A0);
  final Color primaryTeal = const Color(0xFF2884A0);
  final Color accentGold = const Color(0xFFF57C00);

  final bool isSubscribed = true;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allCursus = [];
  List<Map<String, dynamic>> _filteredCursus = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCursus();
  }

  // ---------------- API CALL ----------------
  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Déconnexion",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text("Souhaitez-vous vraiment quitter l'application ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Annuler",
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = await _token();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('$_base/auth/logout/'),
            headers: {'Authorization': 'Token $token'},
          );
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
      }
    }
  }

  Future<void> _fetchCursus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Utilisateur non connecté");

      final response = await http.get(
        Uri.parse("https://yekiapp.pythonanywhere.com/api/apprenant/cursus/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final mapped = data.map<Map<String, dynamic>>((cursus) {
          return {
            'id': cursus['id'],
            'title': cursus['title'],
            'description': cursus['description'] ?? '',
            'teacher': cursus['enseignant_principal'] ?? 'Enseignant Yeki',
            'lessons': cursus['lessons_count'] ?? 0,
            'icon': Icons.menu_book_rounded,
            // On utilise des variations autour du bleu et du teal pour les dégradés
            'gradient': [mainBlue, primaryTeal],
          };
        }).toList();

        setState(() {
          _allCursus = mapped;
          _filteredCursus = mapped;
          _isLoading = false;
        });
      } else {
        throw Exception("Erreur de chargement des cours");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCursus(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCursus = List.from(_allCursus);
      } else {
        final q = query.toLowerCase();
        _filteredCursus = _allCursus.where((c) {
          return c['title'].toLowerCase().contains(q) ||
                 c['teacher'].toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  // ---------------- UI SECTIONS ----------------

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Bonjour Donald",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
              const SizedBox(width: 8),
              const Text("👋", style: TextStyle(fontSize: 22)),
            ],
          ),
          Text(
            "Prêt à apprendre quelque chose aujourd'hui ?",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Barre de recherche stylisée
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: mainBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCursus,
              decoration: InputDecoration(
                hintText: "Rechercher un cours, un prof...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Icon(Icons.search_rounded, color: mainBlue),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: mainBlue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Garder le reste du code inchangé)

  Widget _buildContinueLearning() {
    // Liste simulant les données venant de l'API (dernières lectures de moins de 7 jours)
    final List<Map<String, dynamic>> recentLessons = [
      {
        'title': 'Mathématiques : Les Matrices',
        'chapter': 'Chapitre 4',
        'remaining': '12 min restantes',
        'progress': 0.7,
      },
      {
        'title': 'Physique : Optique Géométrique',
        'chapter': 'Chapitre 2',
        'remaining': '5 min restantes',
        'progress': 0.4,
      },
      {
        'title': 'Anglais : Business Grammar',
        'chapter': 'Unité 1',
        'remaining': '8 min restantes',
        'progress': 0.1,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Continuer la lecture",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
          ),
        ),
        const SizedBox(height: 15),
        
        recentLessons.isEmpty 
          ? _buildMotivationalEmptyState() 
          : SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recentLessons.length,
                itemBuilder: (context, index) {
                  final lesson = recentLessons[index]; // On récupère les données du cours spécifique
                  
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [mainBlue, primaryTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: mainBlue.withOpacity(0.3), 
                          blurRadius: 10, 
                          offset: const Offset(0, 5)
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            Icons.play_circle_fill, 
                            size: 100, 
                            color: Colors.white.withOpacity(0.1)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lesson['title'], // Titre dynamique
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${lesson['chapter']} • ${lesson['remaining']}", // Détails dynamiques
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Action de reprise
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: mainBlue,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                    child: const Text("Reprendre", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        const SizedBox(height: 25),
      ],
    );
  }

  // Nouveau Widget pour motiver l'apprenant
  Widget _buildMotivationalEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Ton "Fond" de palette
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1f5f75).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Illustration ou Icône
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1f5f75).withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Text("🚀", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          // Texte et Bouton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Le savoir n'attend pas !",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1e4f61), // Teal foncé
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tu n'as rien lu cette semaine. Reprends tes bonnes habitudes dès maintenant.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Action pour scroller vers la liste des programmes
                  },
                  child: Row(
                    children: [
                      Text(
                        "Choisir un cours",
                        style: TextStyle(
                          color: const Color(0xFF1f5f75),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1f5f75)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: isSubscribed,
        userRole: "Apprenant",
        username: "Donald",
        avatarUrl: null,
        onNotifications: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsPage(),
            ),
          );
        },
        onSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilPage(),
            ),
          );
        },

      onLogout: () {
        _handleLogout(context);
      },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainBlue))
          : _error != null
              ? Center(child: Text("Oups ! $_error"))
              : RefreshIndicator(
                  onRefresh: _fetchCursus,
                  color: mainBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    // ✅ On ajoute +2 : un pour le header (index 0) et un pour l'espacement final
                    itemCount: _filteredCursus.length + 2, 
                    itemBuilder: (context, index) {
                      // 1. Section Header (Bonjour, Recherche, Continuer la lecture)
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderSection(),
                            _buildContinueLearning(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tes programmes",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }

                      // 2. ✅ ESPACEMENT FINAL : Si on est au dernier index
                      if (index == _filteredCursus.length + 1) {
                        return const SizedBox(height: 100); // Ajuste cette valeur selon la hauteur de ta barre
                      }

                      // 3. Liste des cours (on utilise index - 1 à cause du header)
                      final cursus = _filteredCursus[index - 1];
                      return _buildCursusCard(cursus);
                    },
                  ),
                ),
    );
  }

  Widget _buildCursusCard(Map<String, dynamic> cursus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: mainBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoursDetailTabs(
                coursId: cursus['id'].toString(),
                titre: cursus['title'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mainBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(cursus['icon'], color: mainBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cursus['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          cursus['teacher'],
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                cursus['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.play_lesson_outlined, size: 14, color: mainBlue),
                  const SizedBox(width: 4),
                  Text("${cursus['lessons']} chapitres",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text("Progression", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.3, // Exemple de progression
                  backgroundColor: mainBlue.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(mainBlue),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "EN COURS",
        style: TextStyle(color: accentGold, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
