import 'package:flutter/material.dart';

class AjoutExercicePage extends StatefulWidget {
  const AjoutExercicePage({super.key});

  @override
  State<AjoutExercicePage> createState() => _AjoutExercicePageState();
}

class _AjoutExercicePageState extends State<AjoutExercicePage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _niveau = 1;

  List<Map<String, dynamic>> questions = [];

  void _ajouterQuestion() {
    setState(() {
      questions.add({
        'question': '',
        'reponse': '',
        'points': 1,
        'isQCM': false,
        'options': ['', '', '', ''],
        'bonneOption': 0
      });
    });
  }

  void _enregistrer() {
    if (_titreController.text.isEmpty || questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez remplir le titre et ajouter au moins une question.'),
      ));
      return;
    }

    // Ici tu peux envoyer les données vers ton back-end
    debugPrint("Titre : ${_titreController.text}");
    debugPrint("Description : ${_descriptionController.text}");
    debugPrint("Niveau : $_niveau");
    debugPrint("Questions : $questions");

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Exercice enregistré avec succès !'),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un exercice'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'exercice',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Énoncé / Description',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _niveau,
              items: List.generate(
                5,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Niveau ${i + 1}'),
                ),
              ),
              onChanged: (val) => setState(() => _niveau = val!),
              decoration: const InputDecoration(labelText: 'Niveau de difficulté'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Questions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'Question ${index + 1}'),
                        onChanged: (val) => q['question'] = val,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Question à choix multiple (QCM)'),
                        value: q['isQCM'],
                        onChanged: (val) => setState(() => q['isQCM'] = val),
                      ),
                      q['isQCM']
                          ? Column(
                              children: List.generate(4, (i) {
                                return ListTile(
                                  title: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Option ${i + 1}'),
                                    onChanged: (val) =>
                                        q['options'][i] = val,
                                  ),
                                  leading: Radio<int>(
                                    value: i,
                                    groupValue: q['bonneOption'],
                                    onChanged: (val) => setState(() =>
                                        q['bonneOption'] = val ?? 0),
                                  ),
                                );
                              }),
                            )
                          : TextField(
                              decoration: const InputDecoration(labelText: 'Réponse correcte'),
                              onChanged: (val) => q['reponse'] = val,
                            ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Nombre de points'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) =>
                            q['points'] = int.tryParse(val) ?? 1,
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => questions.removeAt(index)),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _ajouterQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une question'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _enregistrer,
                child: const Text('Valider et enregistrer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: Colors.teal,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
