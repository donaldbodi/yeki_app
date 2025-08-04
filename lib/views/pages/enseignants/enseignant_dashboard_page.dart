import 'package:flutter/material.dart';

class DashboardEnseignantPage extends StatefulWidget {
  final bool isPrincipal;
  final String nomEnseignant;

  const DashboardEnseignantPage({
    super.key,
    required this.isPrincipal,
    required this.nomEnseignant,
  });

  @override
  State<DashboardEnseignantPage> createState() => _DashboardEnseignantPageState();
}

class _DashboardEnseignantPageState extends State<DashboardEnseignantPage> {

  void _afficherProfilApprenant(BuildContext context, Map<String, dynamic> apprenant) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Profil : ${apprenant['nom']}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📧 Email : ${apprenant['email']}"),
          Text("🎓 Niveau : ${apprenant['niveau']}"),
          Text("📈 Progression : ${apprenant['progression']}%"),
          const SizedBox(height: 10),
          const Text("📖 Détails supplémentaires (simulés)..."),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> coursAffectes = [
      {
        "titre": "Maths Terminale C",
        "niveau": "Terminale C",
        "lecons": 12,
        "apprenants": 25,
        "progressionMoyenne": 68,
        "enseignantsSecondaires": ["Mme Ngo", "Mr Biloa"],
        "apprenantsListe": [
          {"nom": "Albert Mvondo", "email": "albert@example.com", "niveau": "Terminale C", "progression": 72},
          {"nom": "Nadine Kamga", "email": "nadine@example.com", "niveau": "Terminale C", "progression": 63},
        ],
      },
      {
        "titre": "Physique Terminale C",
        "niveau": "Terminale C",
        "lecons": 10,
        "apprenants": 20,
        "progressionMoyenne": 54,
        "enseignantsSecondaires": [],
        "apprenantsListe": [
          {"nom": "Albert Mvondo", "email": "albert@example.com", "niveau": "Terminale C", "progression": 72},
          {"nom": "Nadine Kamga", "email": "nadine@example.com", "niveau": "Terminale C", "progression": 63},// moyenne avant, moyeenne appres
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes cours affectés"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ...coursAffectes.map((cours) => _carteCours(context, cours)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _carteCours(BuildContext context, Map<String, dynamic> cours) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📘 ${cours['titre']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("🎓 Niveau : ${cours['niveau']}"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text("👨‍🎓 Apprenants : ${cours['apprenants']}")),
                Expanded(child: Text("📚 Leçons : ${cours['lecons']}")),
                Expanded(child: Text("📈 Progression : ${cours['progressionMoyenne']}%")),
              ],
            ),
            const SizedBox(height: 10),
ExpansionTile(
  title: const Text("👨‍🎓 Apprenants", style: TextStyle(fontWeight: FontWeight.bold)),
  children: [
    ...(cours['apprenantsListe'] as List).map<Widget>((apprenant) => ListTile(
          leading: const Icon(Icons.person),
          title: Text(apprenant['nom']),
          subtitle: Text("Niveau : ${apprenant['niveau']} - Progression : ${apprenant['progression']}%"),
          trailing: const Icon(Icons.info_outline, color: Colors.blue),
          onTap: () => _afficherProfilApprenant(context, apprenant),
        )),
  ],
),
            const SizedBox(height: 10),
            if (widget.isPrincipal) ...[
              const Divider(),
              const Text("👥 Enseignants secondaires", style: TextStyle(fontWeight: FontWeight.bold)),
              ...cours['enseignantsSecondaires'].map<Widget>((nom) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline),
                    title: Text(nom),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        cours['enseignantsSecondaires'].remove(nom);
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  )),
              TextButton.icon(
                onPressed: () => _ajouterEnseignantSecondaire(context, cours),
                icon: const Icon(Icons.person_add),
                label: const Text("Ajouter un enseignant secondaire"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _ajouterEnseignantSecondaire(BuildContext context, Map<String, dynamic> cours) {
    final List<String> tousEnseignants = ["Mr Nono", "Mme Ngo", "Mr Biloa", "Mme Tchounga"];
    String? selection;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter un enseignant secondaire"),
        content: DropdownButtonFormField<String>(
          items: tousEnseignants
              .where((e) => !cours['enseignantsSecondaires'].contains(e))
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => selection = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (selection != null) {
                cours['enseignantsSecondaires'].add(selection);
                Navigator.pop(context);
                (context as Element).markNeedsBuild();
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }
}

//cette page doit aussi etre modulable, seul l'enseignant principal de ce cours peux faire des modifications, a savoir: ajouter/retirer un enseignant secondaire, ajouter une lecon au cours, ajouter