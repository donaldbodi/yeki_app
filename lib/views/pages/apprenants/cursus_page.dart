import 'package:flutter/material.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'cours_detail_page.dart';

class CursusPage extends StatelessWidget {
  final bool isSubscribed = true; // ← Change cette valeur pour simuler l’abonnement

  final List<Map<String, dynamic>> cursusList = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const YekiAppBar(
        title: "Yéki - Mon Cursus",
        subtitle: "Vos matières principales",
        icon: Icons.menu_book_rounded,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cursusList.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Section abonnement
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: isSubscribed ? Colors.orange : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSubscribed
                          ? 'Abonnement actif jusqu\'au 31 Déc. 2025'
                          : 'Aucun abonnement actif',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  isSubscribed
                      ? const Icon(Icons.check_circle, color: Colors.teal, size: 18)
                      : TextButton(
                          onPressed: () {
                            // TODO: Ajouter la logique de souscription
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Fonctionnalité d'abonnement à venir")),
                            );
                          },
                          child: const Text("S'abonner", style: TextStyle(color: Colors.redAccent),),
                        ),
                ],
              ),
            );
          }

          final cursus = cursusList[index - 1];
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
                border: Border.all(
                  width: 1,
                  color: cursus['gradient'].first.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                            color: Color(0xFF1A1A1A),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
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
