import 'package:flutter/material.dart';
import 'cours_detail_page.dart';
import 'paiement_page.dart';

class DetailConcoursPage extends StatelessWidget {
  final String nomConcours;
  final String description;
  final String image;
  final double prix;
  final List<Map<String, String>> modules;

  const DetailConcoursPage({
    super.key,
    required this.nomConcours,
    required this.description,
    required this.prix,
    required this.modules,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF03224C),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                nomConcours,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black38),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.4)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    nomConcours,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF03224C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Prix + inscription
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF008080), Color(0xFF005B5B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "💰 ${prix.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaiementPage(
                                  concours: nomConcours,
                                  montant: prix,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(
                                color: Color(0xFFFFCCBC),
                                width: 1,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            "S'inscrire",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Modules
                  const Text(
                    "📚 Modules au programme",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008080),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: modules.map((module) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF008080),
                            child: Icon(Icons.menu_book_rounded, color: Colors.white),
                          ),
                          title: Text(
                            module['titre'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              module['description'] ?? '',
                              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            /*Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoursDetailTabs(),
                              ),
                            );*/
                          },
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
