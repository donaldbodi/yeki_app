import 'package:flutter/material.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'concours_detail_page.dart';

class ConcoursPage extends StatefulWidget {
  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> {
  String selectedFilter = 'Tous';

  final List<Map<String, dynamic>> concoursList = [
    {
      'titre': 'Concours ENAM',
      'description': 'Administration, Magistrature, Régies financières...',
      'prix': 15000.0,
      'niveau': 'Bac +2',
      'dateLimite': '30 Août 2025',
      'nbModules': '2 modules',
      'souscrit': true,
      'modules': [
        {'titre': 'Physique', 'description': 'Mécanique, électricité.'},
        {'titre': 'Chimie', 'description': 'Chimie organique et minérale.'},
      ],
      'image': 'assets/images/enam.jpeg',
    },
    {
      'titre': 'Concours ENS',
      'description': 'École Normale Supérieure pour enseignants qualifiés.',
      'prix': 10000.0,
      'niveau': 'Baccalauréat',
      'dateLimite': '10 Septembre 2025',
      'nbModules': '1 module',
      'souscrit': false,
      'modules': [
        {'titre': 'Physique', 'description': 'Mécanique, électricité.'},
        {'titre': 'Chimie', 'description': 'Chimie organique et minérale.'},
      ],
      'image': 'assets/images/ens.png',
    },
    {
      'titre': 'Polytech Yaounde',
      'description': 'École Polytechnique de yaounde',
      'prix': 17000.0,
      'niveau': 'Baccalauréat',
      'dateLimite': '10 Septembre 2025',
      'nbModules': '1 module',
      'souscrit': false,
      'modules': [
        {'titre': 'Physique', 'description': 'Mécanique, électricité.'},
        {'titre': 'Chimie', 'description': 'Chimie organique et minérale.'},
      ],
      'image': 'assets/images/polytech.png',
    },
  ];

  List<String> filters = ['Tous', 'Souscrits', 'Non Souscrits'];

  @override
  Widget build(BuildContext context) {
    final filteredList = selectedFilter == 'Tous'
        ? concoursList
        : concoursList
            .where((c) => selectedFilter == 'Souscrits'
                ? c['souscrit'] == true
                : c['souscrit'] == false)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: YekiAppBar(
        title: 'Prépa Concours',
        subtitle: "Excellence & Réussite assurée",
        icon: Icons.school_outlined,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final selected = filter == selectedFilter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                  selectedColor: const Color(0xFF008080),
                  backgroundColor: Colors.grey.shade200,
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final concours = filteredList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailConcoursPage(
                          nomConcours: concours['titre'],
                          description: concours['description'],
                          prix: concours['prix'],
                          modules: concours['modules'],
                          image: concours['image'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 130,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: double.infinity,
                            child: Image.asset(
                              concours['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          concours['titre'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (concours['souscrit'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Text(
                                            'Souscrit',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    concours['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        concours['dateLimite'],
                                        style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined, size: 14, color: Colors.teal),
                                      const SizedBox(width: 4),
                                      Text(
                                        concours['niveau'],
                                        style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${concours['nbModules']} • ${concours['prix'].toInt()} FCFA',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
