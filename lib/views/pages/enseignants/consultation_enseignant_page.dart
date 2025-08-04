import 'package:flutter/material.dart';

class ConsultationCoursEnseignantPage extends StatelessWidget {
  final String nomEnseignant;
  final List<Map<String, dynamic>> cours;

  const ConsultationCoursEnseignantPage({
    super.key,
    required this.nomEnseignant,
    required this.cours,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cours de $nomEnseignant"),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cours.isEmpty
            ? const Center(
                child: Text("Aucun cours assigné.",
                    style: TextStyle(color: Colors.grey)),
              )
            : ListView.builder(
                itemCount: cours.length,
                itemBuilder: (context, index) {
                  final c = cours[index];
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.book, color: Colors.white),
                      ),
                      title: Text(c['titre'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Niveau : ${c['niveau']}"),
                          Text("Matière : ${c['matiere']}"),
                          Text("Apprenants : ${c['apprenants']}"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () {
                          // TODO: Aller vers les détails du cours
                        },
                        child: const Text("Voir"),
                      ),
                    ),
                  );
                }),
      ),
    );
  }
}
