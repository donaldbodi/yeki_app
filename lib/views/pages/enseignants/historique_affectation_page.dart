import 'package:flutter/material.dart';

class HistoriqueAffectationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> historique = [
    {
      'action': 'Ajout',
      'enseignant': 'Mme Noutcha Berthe',
      'cours': 'Mathématiques Terminale',
      'effectuéPar': 'Admin général',
      'date': DateTime(2025, 7, 3, 10, 30),
    },
    {
      'action': 'Retrait',
      'enseignant': 'M. Owona Jules',
      'cours': 'Physique Concours ENS',
      'effectuéPar': 'Enseignant principal',
      'date': DateTime(2025, 7, 2, 16, 0),
    },
    {
      'action': 'Changement de rôle',
      'enseignant': 'Mme Tchinda Eliane',
      'cours': 'Chimie Prépa Bac',
      'effectuéPar': 'Admin général',
      'ancienRôle': 'Enseignant',
      'nouveauRôle': 'Enseignant principal',
      'date': DateTime(2025, 7, 1, 9, 0),
    },
  ];

  HistoriqueAffectationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des Affectations"),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: ListView.builder(
        itemCount: historique.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = historique[index];
          final action = item['action'];
          final date = item['date'] as DateTime;

          IconData icon;
          Color color;

          switch (action) {
            case 'Ajout':
              icon = Icons.person_add;
              color = Colors.green;
              break;
            case 'Retrait':
              icon = Icons.person_remove;
              color = Colors.red;
              break;
            case 'Changement de rôle':
              icon = Icons.swap_horiz;
              color = Colors.orange;
              break;
            default:
              icon = Icons.info;
              color = Colors.grey;
          }

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              title: Text(
                "$action de ${item['enseignant']}",
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cours : ${item['cours']}"),
                  if (action == 'Changement de rôle')
                    Text("De ${item['ancienRôle']} à ${item['nouveauRôle']}"),
                  Text("Effectué par : ${item['effectuéPar']}"),
                  Text("Le ${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
