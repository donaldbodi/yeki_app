import 'package:flutter/material.dart';

enum TypeEnseignantConcours { enseignant, principal, admin, superadmin }

class ListeConcoursEnseignantPage extends StatelessWidget {
  final TypeEnseignantConcours typeEnseignant;

  const ListeConcoursEnseignantPage({super.key, required this.typeEnseignant});

  final List<Map<String, dynamic>> concours = const [
    {
      'titre': 'Concours Médecine 2025',
      'date': '15 Septembre 2025',
      'prix': 25000,
      'enseignants': ['Dr. Fokou', 'Mme Ngo'],
      'image': 'assets/images/medecine.jpg',
    },
    {
      'titre': 'Concours Polytechnique',
      'date': '10 Août 2025',
      'prix': 20000,
      'enseignants': ['M. Tamo'],
      'image': 'assets/images/polytech.jpg',
    },
  ];

  void _ajouterOuModifierResponsable(BuildContext context, String concours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modification - $concours'),
        content: const Text('Interface d’ajout/modification à implémenter'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Concours assignés'),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: ListView.builder(
        itemCount: concours.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = concours[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(item['image'],
                      height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['titre'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(item['date']),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, size: 16),
                          const SizedBox(width: 6),
                          Text('${item['prix']} FCFA'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: List.generate(
                          item['enseignants'].length,
                          (i) => Chip(
                            label: Text(item['enseignants'][i]),
                            backgroundColor: Colors.blue[50],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (typeEnseignant != TypeEnseignantConcours.enseignant)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text("Modifier responsables"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _ajouterOuModifierResponsable(
                                context, item['titre']),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

