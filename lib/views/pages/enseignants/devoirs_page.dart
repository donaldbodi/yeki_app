import 'package:flutter/material.dart';

class Question {
  final String enonce;
  final List<String>? choix; // null si ce n’est pas un QCM
  final String correction;
  final int points;
  final bool estQCM;

  Question({
    required this.enonce,
    this.choix,
    required this.correction,
    required this.points,
    required this.estQCM,
  });
}

class ExerciceDevoir {
  final String titre;
  final String enonce;
  final List<Question> questions;

  ExerciceDevoir({
    required this.titre,
    required this.enonce,
    required this.questions,
  });
}

class Devoir {
  final String titre;
  final String dateLimite;
  final List<ExerciceDevoir> exercices;
  bool estDeroule;

  Devoir({
    required this.titre,
    required this.dateLimite,
    required this.exercices,
    this.estDeroule = false,
  });
}

class DevoirsPageEnseignant extends StatefulWidget {
  final bool estEnseignantPrincipal;

  const DevoirsPageEnseignant({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPageEnseignant> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPageEnseignant> {

  List<Devoir> devoirs = [
  Devoir(
    titre: "Devoir maison : Chapitre 1",
    dateLimite: "2025-07-20",
    exercices: [
      ExerciceDevoir(
        titre: "Exercice 1",
        enonce: "Résolvez les équations suivantes...",
        questions: [
          Question(
              enonce: "x² - 4 = 0",
              correction: "x = ±2",
              points: 2,
              estQCM: false),
          Question(
              enonce: "x² + 2x + 1 = 0",
              correction: "x = -1",
              points: 3,
              estQCM: false),
        ],
      ),
    ],
  ),
];

String filtreDevoir = "";

  void _modifierDevoir(int index) {
  final devoir = devoirs[index];
  final titreCtrl = TextEditingController(text: devoir.titre);
  final dateCtrl = TextEditingController(text: devoir.dateLimite);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Modifier le devoir"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre")),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date limite")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            setState(() {
              devoirs[index] = Devoir(
                titre: titreCtrl.text,
                dateLimite: dateCtrl.text,
                exercices: devoir.exercices,
              );
            });
            Navigator.pop(context);
          },
          child: const Text("Modifier"),
        ),
      ],
    ),
  );
}

  Widget devoirsFiltres() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
    child: TextField(
      decoration: const InputDecoration(
        labelText: "Filtrer les devoirs par titre ou date",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        setState(() => filtreDevoir = val.toLowerCase());
      },
    ),
  );
}

  Future<Question?> _ajouterQuestion(BuildContext context) async {
  final enonceCtrl = TextEditingController();
  final correctionCtrl = TextEditingController();
  final pointsCtrl = TextEditingController();
  final List<String> choix = [];
  bool estQCM = false;

  return await showDialog<Question>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text("Nouvelle question"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    value: estQCM,
                    title: const Text("Question à choix multiple"),
                    onChanged: (val) => setStateDialog(() => estQCM = val),
                  ),
                  TextField(controller: enonceCtrl, decoration: const InputDecoration(labelText: "Énoncé")),
                  TextField(controller: correctionCtrl, decoration: const InputDecoration(labelText: "Correction")),
                  TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: "Nombre de points"), keyboardType: TextInputType.number),
                  if (estQCM)
                    Column(
                      children: [
                        for (int i = 0; i < choix.length; i++)
                          ListTile(title: Text(choix[i])),
                        TextField(
                          decoration: const InputDecoration(labelText: "Ajouter un choix"),
                          onSubmitted: (val) => setStateDialog(() => choix.add(val)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (enonceCtrl.text.isNotEmpty && correctionCtrl.text.isNotEmpty) {
                    Navigator.pop(
                      context,
                      Question(
                        enonce: enonceCtrl.text,
                        correction: correctionCtrl.text,
                        points: int.tryParse(pointsCtrl.text) ?? 0,
                        estQCM: estQCM,
                        choix: estQCM ? choix : null,
                      ),
                    );
                  }
                },
                child: const Text("Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<ExerciceDevoir?> _creerExercice(BuildContext context) async {
  final titreCtrl = TextEditingController();
  final enonceCtrl = TextEditingController();
  final questions = <Question>[];

  return await showDialog<ExerciceDevoir>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text("Nouvel exercice"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre de l'exercice")),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Ajouter une question"),
                onPressed: () async {
                  final q = await _ajouterQuestion(context);
                  if (q != null) {
                    setStateDialog(() => questions.add(q));
                  }
                },
              ),
              Text("Questions ajoutées : ${questions.length}")
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (titreCtrl.text.isNotEmpty && questions.isNotEmpty) {
                Navigator.pop(
                    ctx,
                    ExerciceDevoir(enonce: enonceCtrl.text,
                        titre: titreCtrl.text, questions: questions));
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    ),
  );
}

  void _ajouterDevoir(BuildContext context) {
  final titreCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final exercices = <ExerciceDevoir>[];

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Créer un nouveau devoir"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: "Titre du devoir")),
                  TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date limite (ex: 2025-07-20)")),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final exercice = await _creerExercice(context);
                      if (exercice != null) {
                        setStateDialog(() {
                          exercices.add(exercice);
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un exercice"),
                  ),
                  const SizedBox(height: 10),
                  Text("Exercices ajoutés : ${exercices.length}"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () {
                  if (titreCtrl.text.isNotEmpty && dateCtrl.text.isNotEmpty) {
                    setState(() {
                      devoirs.add(Devoir(
                        titre: titreCtrl.text,
                        dateLimite: dateCtrl.text,
                        exercices: exercices,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Créer"),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _supprimerDevoir(int index) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Supprimer ce devoir"),
      content: const Text("Voulez-vous vraiment supprimer ce devoir ?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Supprimer"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() {
      devoirs.removeAt(index);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [
      if (widget.estEnseignantPrincipal)
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Nouveau devoir"),
              onPressed: () => _ajouterDevoir(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008080),
              ),
            ),
          ),
        ),
      Expanded(
        child: devoirs.isEmpty
            ? const Center(child: Text("Aucun devoir disponible."))
            : ListView.builder(
                itemCount: devoirs.length,
                itemBuilder: (_, index) {
                  final d = devoirs[index];
                  devoirs.where((d) =>
                  d.titre.toLowerCase().contains(filtreDevoir) ||
                  d.dateLimite.toLowerCase().contains(filtreDevoir)).toList();
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Text(d.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("📅 Limite : ${d.dateLimite}"),
                      initiallyExpanded: d.estDeroule,
                      children: [
                        ...d.exercices.map((exo) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("📘 ${exo.titre}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text("📝 Énoncé : ${exo.enonce}"),
                                  const SizedBox(height: 6),
                                  ...exo.questions.map((q) => ListTile(
                                        leading: q.estQCM
                                            ? const Icon(Icons.check_box)
                                            : const Icon(Icons.short_text),
                                        title: Text(q.enonce),
                                        subtitle: Text("Correction : ${q.correction} • ${q.points} pts"),
                                      )),
                                ],
                              ),
                            )),
                        if (widget.estEnseignantPrincipal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _modifierDevoir(index),
                                icon: const Icon(Icons.edit),
                                label: const Text("Modifier"),
                              ),
                              TextButton.icon(
                                onPressed: () => _supprimerDevoir(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
      )
    ],
  );
  }
}
