import 'package:flutter/material.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'concours_detail_page.dart';

class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> {
  String selectedFilter = 'Tous';
  final bool isSubscribed = true;

  final List<Map<String, dynamic>> concoursList = [
    {
      'titre': 'Concours ENAM',
      'description': 'Administration, Magistrature, Régies financières...',
      'prix': 15000.0,
      'niveau': 'Bac +2',
      'dateLimite': '30 Août 2025',
      'nbModules': '2 modules',
      'souscrit': true,
      'modules': [],
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
      'modules': [],
      'image': 'assets/images/ens.png',
    },
    {
      'titre': 'Polytech Yaoundé',
      'description': 'École Polytechnique de Yaoundé',
      'prix': 17000.0,
      'niveau': 'Baccalauréat',
      'dateLimite': '10 Septembre 2025',
      'nbModules': '1 module',
      'souscrit': false,
      'modules': [],
      'image': 'assets/images/polytech.png',
    },
  ];

  final List<String> filters = ['Tous', 'Souscrits', 'Non Souscrits'];

  @override
  Widget build(BuildContext context) {
    final filteredList = selectedFilter == 'Tous'
        ? concoursList
        : concoursList.where((c) {
            return selectedFilter == 'Souscrits'
                ? c['souscrit'] == true
                : c['souscrit'] == false;
          }).toList();

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

      body: CustomScrollView(
        slivers: [

          /// 🔹 BARRE DE FILTRES (scrollable avec la page)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final selected = filter == selectedFilter;

                    return ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedFilter = filter),
                      selectedColor: const Color(0xFF008080),
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          /// 🔹 LISTE DES CONCOURS
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final concours = filteredList[index];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: GestureDetector(
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
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
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
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            child: Image.asset(
                              concours['image'],
                              width: 105,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          concours['titre'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (concours['souscrit'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Souscrit',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
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
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${concours['nbModules']} • ${concours['prix'].toInt()} FCFA',
                                    style: const TextStyle(
                                      fontSize: 12,
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
              childCount: filteredList.length,
            ),
          ),
        ],
      ),
    );
  }
}

