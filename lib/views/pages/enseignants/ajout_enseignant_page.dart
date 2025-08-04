import 'package:flutter/material.dart';

class AjoutEnseignantPage extends StatefulWidget {
  final String roleUtilisateur; // 'enseignant principal', 'enseignant administrateur', 'admin général'
  final String nomCours;

  const AjoutEnseignantPage({
    super.key,
    required this.roleUtilisateur,
    required this.nomCours,
  });

  @override
  State<AjoutEnseignantPage> createState() => _AjoutEnseignantPageState();
}

class _AjoutEnseignantPageState extends State<AjoutEnseignantPage> {
  String searchQuery = '';
  String? selectedRole;

  List<Map<String, String>> enseignantsDispo = [
    {'nom': 'Ateba Lionel', 'email': 'ateba@yeki.com'},
    {'nom': 'Ngono Flavien', 'email': 'flavien@yeki.com'},
    {'nom': 'Mbappe Martine', 'email': 'mbappe@yeki.com'},
  ];

  List<String> getRolesAutorises() {
    switch (widget.roleUtilisateur) {
      case 'admin général':
        return ['enseignant', 'enseignant principal', 'enseignant administrateur'];
      case 'enseignant administrateur':
        return ['enseignant', 'enseignant principal'];
      case 'enseignant principal':
        return ['enseignant'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final enseignantsFiltres = enseignantsDispo
        .where((ens) =>
            ens['nom']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
            ens['email']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un enseignant à ${widget.nomCours}"),
        backgroundColor: const Color(0xFF03224C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Rechercher un enseignant",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: enseignantsFiltres.length,
                itemBuilder: (context, index) {
                  final enseignant = enseignantsFiltres[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundImage: AssetImage("assets/images/avatar.png"),
                      ),
                      title: Text(enseignant['nom']!),
                      subtitle: Text(enseignant['email']!),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _showAjoutDialog(context, enseignant);
                        },
                        child: const Text("Ajouter"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAjoutDialog(BuildContext context, Map<String, String> enseignant) {
    final roles = getRolesAutorises();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Ajouter ${enseignant['nom']}"),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          items: roles
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role[0].toUpperCase() + role.substring(1)),
                  ))
              .toList(),
          decoration: const InputDecoration(
            labelText: "Choisir un rôle",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => selectedRole = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedRole != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "${enseignant['nom']} a été ajouté comme $selectedRole à ${widget.nomCours}."),
                  ),
                );
                setState(() => selectedRole = null);
              }
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }
}
