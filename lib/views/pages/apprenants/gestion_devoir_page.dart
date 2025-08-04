import 'package:flutter/material.dart';

class GestionDevoirsPage extends StatefulWidget {
  final String typeEnseignant; // enseignant, enseignantPrincipal, admin, adminGeneral

  const GestionDevoirsPage({super.key, required this.typeEnseignant});

  @override
  State<GestionDevoirsPage> createState() => _GestionDevoirsPageState();
}

class _GestionDevoirsPageState extends State<GestionDevoirsPage> {
  final List<Map<String, dynamic>> devoirs = [
    {
      'titre': 'Devoir Maths 1',
      'matiere': 'Mathématiques',
      'niveau': 'Terminale',
      'statut': 'en cours',
      'rendus': 18,
      'total': 25,
    },
    {
      'titre': 'Physique TD 2',
      'matiere': 'Physique',
      'niveau': '1ère',
      'statut': 'terminé',
      'rendus': 23,
      'total': 23,
    },
  ];

  void _supprimerDevoir(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer ce devoir ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                devoirs.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void _ajouterDevoir() {
    // Redirection ou affichage d'une modal d'ajout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Formulaire d'ajout de devoir (à développer)")),
    );
  }

  bool get peutAjouter => widget.typeEnseignant != 'enseignant';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Devoirs"),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              // filtre par matière ou niveau
            },
          ),
        ],
      ),
      floatingActionButton: peutAjouter
          ? FloatingActionButton.extended(
              onPressed: _ajouterDevoir,
              label: const Text("Ajouter"),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.deepOrange,
            )
          : null,
      body: devoirs.isEmpty
          ? const Center(child: Text("Aucun devoir disponible"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devoirs.length,
              itemBuilder: (context, index) {
                final d = devoirs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      d['titre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Matière : ${d['matiere']}"),
                        Text("Niveau : ${d['niveau']}"),
                        Text("Statut : ${d['statut']}"),
                        Text("Rendus : ${d['rendus']}/${d['total']}"),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (peutAjouter)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () {
                              // Modifier
                            },
                          ),
                        if (peutAjouter)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _supprimerDevoir(index),
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
