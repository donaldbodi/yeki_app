import 'package:flutter/material.dart';

class ProfilEnseignantPage extends StatelessWidget {
  final Map<String, dynamic> enseignant;
  final bool peutRetirer; // dépend du rôle de l'utilisateur

  const ProfilEnseignantPage({
    super.key,
    required this.enseignant,
    this.peutRetirer = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> coursAffectes = enseignant['cours'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil de l’Enseignant"),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(enseignant['avatar'] ?? 'assets/images/avatar.png'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              enseignant['nom'] ?? 'Nom Inconnu',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              enseignant['role'] ?? 'Rôle inconnu',
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, color: Colors.blueGrey.shade700),
                const SizedBox(width: 6),
                Text(enseignant['email'] ?? '---'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Colors.blueGrey.shade700),
                const SizedBox(width: 6),
                Text(enseignant['telephone'] ?? '---'),
              ],
            ),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cours assignés",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: coursAffectes.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.book_outlined, color: Colors.teal),
                      title: Text(coursAffectes[index]),
                      trailing: peutRetirer
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                // Confirmer retrait
                                _showRetraitDialog(context, coursAffectes[index]);
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showRetraitDialog(BuildContext context, String cours) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Retirer l'enseignant du cours \"$cours\" ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Enseignant retiré de \"$cours\".")),
              );
            },
            child: const Text("Confirmer"),
          )
        ],
      ),
    );
  }
}
