// admin_enseignant_dashboard_page.dart

import 'package:flutter/material.dart';

class AdminEnseignantDashboardPage extends StatefulWidget {
  final String parcours;

  const AdminEnseignantDashboardPage({super.key, required this.parcours});

  @override
  State<AdminEnseignantDashboardPage> createState() =>
      _AdminEnseignantDashboardPageState();
}

class _AdminEnseignantDashboardPageState
    extends State<AdminEnseignantDashboardPage> {
  String? selectedCategorie;
  String? selectedNiveau;
  String? selectedDepartement;
  String? selectedCategorieStat;
  String? selectedNiveauStat;
  String? selectedDepartementStat;
  String? selectedNiveauSupStat;
  String? selectedConcoursStat;
  List<Map<String, dynamic>> prepas = [
    {
      "nom": "Prépa MINES",
      "description": "Concours des grandes écoles d’ingénieur.",
      "prix": 45000,
      "dateLimite": DateTime(2025, 10, 30),
      "arreter": false,
      "photo": "assets/images/prepa.jpg",
      "cours": [
        {"titre": "Mathématiques MINES", "enseignant": "Mme Tchounga"},
        {"titre": "Physique MINES", "enseignant": "Dr Essomba"},
      ]
    },
  ];

  List<String> enseignants = [
    "Mme Tchounga",
    "Mr Ndifor",
    "Dr Essomba",
    "Mme Ngo"
  ];
  List<Map<String, dynamic>> cours = [];

  final Map<String, List<String>> categoriesSecondaire = {
    "Secondaire Francophone": ["Générale", "Technique"],
    "Secondaire Anglophone": ["General", "Technical"],
  };

  final Map<String, List<String>> niveauxSecondaire = {
    "Générale": ["6e", "5e", "4e", "3e", "2nde", "1ère", "Terminale C"],
    "Technique": ["1ère année", "2e année", "3e année"],
    "General": ["Form 1", "Form 2", "Form 3", "Form 4"],
    "Technical": ["Year 1", "Year 2", "Year 3"],
  };

  final Map<String, List<String>> niveauxSup = {
    "Physique": ["L1", "L2", "L3"],
    "Mathématiques": ["L1", "L2", "L3"],
    "Génie Informatique": ["L1", "L2", "L3"],
    "Génie des Procédés Minéralurgiques": ["L1", "L2", "L3"],
  };

  final List<String> departements = [
    "Physique",
    "Mathématiques",
    "Génie Informatique",
    "Génie des Procédés Minéralurgiques"
  ];

  final List<String> concoursPrepa = [
    "Concours X",
    "Concours ENS",
    "Concours MINES"
  ];

  void _ajouterCoursPrepa(int prepaIndex) {
    final _titreCtrl = TextEditingController();
    String? enseignantChoisi;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter un cours au Prépa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(labelText: "Titre du cours"),
            ),
            DropdownButtonFormField<String>(
              decoration:
                  const InputDecoration(labelText: "Enseignant principal"),
              value: enseignantChoisi,
              items: enseignants
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => enseignantChoisi = val,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (_titreCtrl.text.isNotEmpty && enseignantChoisi != null) {
                setState(() {
                  prepas[prepaIndex]['cours'].add({
                    "titre": _titreCtrl.text,
                    "enseignant": enseignantChoisi
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  void _editerPrepa(int index) {
    final TextEditingController _descCtrl =
        TextEditingController(text: prepas[index]['description']);
    final TextEditingController _prixCtrl =
        TextEditingController(text: prepas[index]['prix'].toString());
    DateTime? dateLimite = prepas[index]['dateLimite'];
    bool arreter = prepas[index]['arreter'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le Prépa"),
        content: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prix (FCFA)"),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text("Date limite"),
                  subtitle: Text(
                      "${dateLimite?.day}/${dateLimite?.month}/${dateLimite?.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateLimite ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null)
                      setModalState(() => dateLimite = picked);
                  },
                ),
                SwitchListTile(
                  title: const Text("Arrêté ?"),
                  value: arreter,
                  onChanged: (v) => setModalState(() => arreter = v),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                prepas[index]['description'] = _descCtrl.text;
                prepas[index]['prix'] = int.tryParse(_prixCtrl.text) ?? 0;
                prepas[index]['dateLimite'] = dateLimite;
                prepas[index]['arreter'] = arreter;
              });
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _ajouterCours() {
    final _titreCtrl = TextEditingController();
    String? categorie;
    String? niveau;
    String? departement;
    String? concours;
    String? enseignant;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Créer un nouveau cours"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titreCtrl,
                  decoration:
                      const InputDecoration(labelText: "Titre du cours"),
                ),
                const SizedBox(height: 10),
                if (widget.parcours.contains("Secondaire"))
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Catégorie"),
                    value: categorie,
                    items: categoriesSecondaire[widget.parcours]!
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => categorie = v),
                  ),
                if (widget.parcours.contains("Secondaire") && categorie != null)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Niveau"),
                    value: niveau,
                    items: niveauxSecondaire[categorie]!
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => niveau = v),
                  ),
                if (widget.parcours == "Supérieur")
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Département"),
                    value: departement,
                    items: departements
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => departement = v),
                  ),
                if (widget.parcours == "Supérieur" && departement != null)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Niveau"),
                    value: niveau,
                    items: niveauxSup[departement]!
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => niveau = v),
                  ),
                if (widget.parcours == "Prépas")
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Concours"),
                    value: concours,
                    items: concoursPrepa
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => concours = v),
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: "Enseignant principal"),
                  value: enseignant,
                  items: enseignants
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => enseignant = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (_titreCtrl.text.isNotEmpty && enseignant != null) {
                setState(() {
                  cours.add({
                    "titre": _titreCtrl.text,
                    "enseignant": enseignant,
                    "categorie": categorie,
                    "niveau": niveau,
                    "departement": departement,
                    "concours": concours,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          )
        ],
      ),
    );
  }

  void _creerPrepa() {
    final _titreCtrl = TextEditingController();
    final _descCtrl = TextEditingController();
    final _prixCtrl = TextEditingController();
    DateTime? dateLimite = DateTime.now().add(const Duration(days: 30));
    bool arreter = false;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Créer un nouveau Prépa"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titreCtrl,
                  decoration: const InputDecoration(labelText: "Nom du prépa"),
                ),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prix (FCFA)"),
                ),
                ListTile(
                  title: const Text("Date limite"),
                  subtitle: Text(
                      "${dateLimite?.day}/${dateLimite?.month}/${dateLimite?.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateLimite!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null)
                      setStateDialog(() => dateLimite = picked);
                  },
                ),
                SwitchListTile(
                  title: const Text("Arrêté ?"),
                  value: arreter,
                  onChanged: (v) => setStateDialog(() => arreter = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                prepas.add({
                  "nom": _titreCtrl.text,
                  "description": _descCtrl.text,
                  "prix": int.tryParse(_prixCtrl.text) ?? 0,
                  "dateLimite": dateLimite,
                  "arreter": arreter,
                  "image": "assets/images/prepa.jpg",
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Créer"),
          )
        ],
      ),
    );
  }

  void _changerEnseignant(Map<String, dynamic> coursItem) {
    String? selected = coursItem['enseignant'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Changer l'enseignant principal"),
        content: DropdownButtonFormField<String>(
          value: selected,
          items: enseignants
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => selected = v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                coursItem['enseignant'] = selected;
              });
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          )
        ],
      ),
    );
  }

  Widget _statistiquesGlobales() {
    String parcours = widget.parcours;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📊 Statistiques globales - $parcours",
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008080))),
                const Icon(Icons.bar_chart, color: Color(0xFF008080))
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoItem(Icons.group, "Apprenants : 1 240"),
                _infoItem(Icons.book, "Cours : 85"),
                _infoItem(Icons.assignment, "Devoirs : 312"),
                _infoItem(Icons.lightbulb, "Exercices : 470"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _blocStatistiques() {
    String parcours = widget.parcours;

    if (parcours.contains("Secondaire")) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Catégorie"),
            value: selectedCategorieStat,
            items: categoriesSecondaire[parcours]!
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedCategorieStat = v;
                selectedNiveauStat = null;
              });
            },
          ),
          if (selectedCategorieStat != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Niveau"),
              value: selectedNiveauStat,
              items: niveauxSecondaire[selectedCategorieStat!]!
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedNiveauStat = v),
            ),
          if (selectedNiveauStat != null)
            _statistiques(
                "📚 Stats ${selectedCategorieStat!} - ${selectedNiveauStat!}")
        ],
      );
    }

    if (parcours == "Supérieur") {
      return Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Département"),
            value: selectedDepartementStat,
            items: departements
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedDepartementStat = v;
                selectedNiveauSupStat = null;
              });
            },
          ),
          if (selectedDepartementStat != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Niveau"),
              value: selectedNiveauSupStat,
              items: niveauxSup[selectedDepartementStat!]!
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedNiveauSupStat = v),
            ),
          if (selectedNiveauSupStat != null)
            _statistiques(
                "🎓 ${selectedDepartementStat!} - ${selectedNiveauSupStat!}")
        ],
      );
    }

    if (parcours == "Prépas") {
      return Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Concours"),
            value: selectedConcoursStat,
            items: concoursPrepa
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedConcoursStat = v),
          ),
          if (selectedConcoursStat != null)
            _statistiques("🧪 Statistiques Concours ${selectedConcoursStat!}")
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statistiques(String label) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal)),
            const SizedBox(height: 8),
            const Text("👨‍🎓 Apprenants : 120"),
            const Text("📚 Cours : 10"),
            const Text("📝 Devoirs : 14"),
            const Text("💡 Exercices : 18"),
          ],
        ),
      ),
    );
  }

  Widget _listeCours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cours
          .map((c) => Card(
                child: ListTile(
                  title: Text(c['titre'] ?? 'Non défini'),
                  subtitle: Text("👨‍🏫 ${c['enseignant'] ?? 'Non défini'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _changerEnseignant(c),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _cartePrepa(int index) {
    final p = prepas[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(p['photo'],
                  height: 140, fit: BoxFit.cover, width: double.infinity),
            ),
            const SizedBox(height: 10),
            Text("🧪 ${p['nom']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal)),
            Text("📜 ${p['description']}"),
            Text("💰 Prix : ${p['prix']} FCFA"),
            Text(
                "📅 Limite : ${p['dateLimite'].day}/${p['dateLimite'].month}/${p['dateLimite'].year}"),
            Text("🚫 Arrêté : ${p['arreter'] ? "Oui" : "Non"}"),
            const SizedBox(height: 10),
            const Text("📚 Cours associés :",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...p['cours'].map<Widget>(
                (c) => Text("✔️ ${c['titre']} (${c['enseignant']})")),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _editerPrepa(index),
                  icon: const Icon(Icons.edit),
                  label: const Text("Modifier"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _ajouterCoursPrepa(index),
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter cours"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard - ${widget.parcours}"),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterCours,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau cours"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("📊 Statistiques du parcours ${widget.parcours}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _statistiquesGlobales(),
            const Text("📈 Statistiques personnalisées",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _blocStatistiques(),
            const SizedBox(height: 20),
            _listeCours(),
            const SizedBox(height: 30),
            if (widget.parcours == "Prépas")
              const Text("🎯 Prépas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (widget.parcours == "Prépas")
              ...List.generate(prepas.length, (index) => _cartePrepa(index)),
            if (widget.parcours == "Prépas")
              ElevatedButton.icon(
                icon: const Icon(Icons.library_add),
                label: const Text("Créer un nouveau Prépa"),
                onPressed: _creerPrepa,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
          ],
        ),
      ),
    );
  }
}
