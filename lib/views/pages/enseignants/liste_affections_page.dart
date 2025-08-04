import 'package:flutter/material.dart';

class ListeAffectationsPage extends StatelessWidget {
  final String nomCours;
  final String roleUtilisateur; // 'enseignant', 'enseignant principal', 'enseignant administrateur', 'admin général'

  ListeAffectationsPage({
    required this.nomCours,
    required this.roleUtilisateur,
  });

  final List<Map<String, dynamic>> enseignantsAffectes = [
    {
      'nom': 'M. Tamo Pierre',
      'role': 'enseignant',
      'photo': 'assets/images/avatar1.png',
      'date': '01/07/2025',
      'online': true,
    },
    {
      'nom': 'Mme Fokou Nathalie',
      'role': 'enseignant principal',
      'photo': 'assets/images/avatar2.png',
      'date': '29/06/2025',
      'online': false,
    },
    {
      'nom': 'Dr. Ngo Fils',
      'role': 'enseignant administrateur',
      'photo': 'assets/images/avatar3.png',
      'date': '25/06/2025',
      'online': true,
    },
  ];

  bool peutRetirer(String roleCible) {
    if (roleUtilisateur == 'admin général') return true;
    if (roleUtilisateur == 'enseignant administrateur' && roleCible == 'enseignant principal') return true;
    if (roleUtilisateur == 'enseignant principal' && roleCible == 'enseignant') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Affectations - $nomCours"),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: enseignantsAffectes.length,
        itemBuilder: (context, index) {
          final enseignant = enseignantsAffectes[index];

          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(enseignant['photo']),
                    radius: 26,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor:
                          enseignant['online'] ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              title: Text(
                enseignant['nom'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${enseignant['role']} • Affecté le ${enseignant['date']}",
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: peutRetirer(enseignant['role'])
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Confirmer le retrait"),
                            content: Text(
                                "Voulez-vous vraiment retirer ${enseignant['nom']} de ce cours ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Annuler"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "${enseignant['nom']} a été retiré.")),
                                  );
                                },
                                child: const Text("Confirmer"),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
