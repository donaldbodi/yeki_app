import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _allCursus = [
    {
      'title': 'Mathématiques',
      'description': 'Analyse, Algèbre, Géométrie et plus',
      'teacher': 'Dr. Bodi',
      'lessons': 18,
      'assignments': 6,
      'icon': Icons.calculate_rounded,
      'gradient': [Color(0xFF00B4DB), Color(0xFF0083B0)],
    },
    {
      'title': 'Physique',
      'description': 'Mécanique, Électromagnétisme',
      'teacher': 'Mme. Tchatchoua',
      'lessons': 22,
      'assignments': 8,
      'icon': Icons.science_rounded,
      'gradient': [Color(0xFF4AC29A), Color(0xFFBDFFF3)],
    },
    {
      'title': 'Chimie',
      'description': 'Organique, Inorganique, Analyse',
      'teacher': 'Dr. Ayissi',
      'lessons': 17,
      'assignments': 5,
      'icon': Icons.bubble_chart_rounded,
      'gradient': [Color(0xFFFF6A00), Color(0xFFFFC371)],
    },
    {
      'title': 'SVT',
      'description': 'Biologie humaine, animale, végétale',
      'teacher': 'Mme. Bilong',
      'lessons': 20,
      'assignments': 7,
      'icon': Icons.eco_rounded,
      'gradient': [Color(0xFF00C9FF), Color(0xFF92FE9D)],
    },
  ];

  late List<Map<String, dynamic>> _filteredCursus;

  @override
  void initState() {
    super.initState();
    _filteredCursus = List.from(_allCursus);
  }

  void _filterCursus(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCursus = List.from(_allCursus);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCursus = _allCursus.where((cursus) {
          return cursus['title'].toLowerCase().contains(lowerQuery) ||
              cursus['description'].toLowerCase().contains(lowerQuery) ||
              cursus['teacher'].toLowerCase().contains(lowerQuery);
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

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCursus.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          /// 🔍 BARRE DE RECHERCHE
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

          /// 📚 CARTES DES COURS
          final cursus = _filteredCursus[index - 1];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoursDetailTabs()),
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
