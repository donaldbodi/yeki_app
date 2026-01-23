import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../widgets/yeki_app_bar.dart';
import 'cours_detail_page.dart';

class CursusPage extends StatefulWidget {
  const CursusPage({super.key});

  @override
  State<CursusPage> createState() => _CursusPageState();
}

class _CursusPageState extends State<CursusPage> {
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

  /// 🔐 APPEL API AVEC TOKEN
  Future<void> _fetchCursus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

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
            'teacher': cursus['enseignant_principal'] ?? '—',
            'lessons': cursus['lessons_count'] ?? 0,
            'assignments': cursus['assignments_count'] ?? 0,
            'icon': Icons.school_rounded,
            'gradient': const [Color(0xFF00B4DB), Color(0xFF0083B0)],
          };
        }).toList();

        setState(() {
          _allCursus = mapped;
          _filteredCursus = mapped;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        throw Exception("Session expirée");
      } else {
        throw Exception("Erreur serveur");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 🔍 RECHERCHE
  void _filterCursus(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCursus = List.from(_allCursus);
      } else {
        final q = query.toLowerCase();
        _filteredCursus = _allCursus.where((c) {
          return c['title'].toLowerCase().contains(q) ||
              c['description'].toLowerCase().contains(q) ||
              c['teacher'].toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: isSubscribed,
        userRole: "Apprenant",
        username: "Bodi Donald",
        avatarUrl: null,
        onNotifications: () {},
        onSettings: () {},
        onLogout: () {},
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Erreur : $_error"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCursus.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                /// 🔍 BARRE DE RECHERCHE
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterCursus,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.black54),
                        hintText: "Rechercher un cours, professeur...",
                        border: InputBorder.none,
                      ),
                    ),
                  );
                }

                /// 📚 CARTE CURSUS
                final cursus = _filteredCursus[index - 1];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoursDetailTabs(
                              coursId: cursus['id'].toString(), titre:cursus['title'],
                            ),
                          ),
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cursus['gradient'].first.withOpacity(0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: cursus['gradient'],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cursus['icon'],
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cursus['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cursus['description'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prof : ${cursus['teacher']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${cursus['lessons']} leçons • ${cursus['assignments']} devoirs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
