import 'package:flutter/material.dart';

class ExercicesCoursPage extends StatefulWidget {
  const ExercicesCoursPage({super.key});

  @override
  State<ExercicesCoursPage> createState() => _ExercicesCoursPageState();
}

class _ExercicesCoursPageState extends State<ExercicesCoursPage> {
  int etoileFiltre = 0;

  final Map<String, String> reponsesDonnees = {};
  final Map<String, String> corrections = {};
  final Map<int, bool> evalExerciceFaite = {};

  final List<Map<String, dynamic>> historiqueEvaluations = [];

  final Map<int, List<Map<String, dynamic>>> exercicesParEtoiles = {
    2: [
      {
        'titre': 'Notions générales',
        'etoiles': 2,
        'enonce': 'Répondez aux questions suivantes.',
        'questions': [
          {
            'text': 'Quelle est la capitale du Cameroun ?',
            'type': 'qcm',
            'choix': ['Yaoundé', 'Douala', 'Bamenda'],
            'reponse': 'Yaoundé',
            'points': 2,
          },
          {
            'text': 'Année de l’indépendance du Cameroun ?',
            'type': 'texte',
            'reponse': '1960',
            'points': 3,
          }
        ],
      },
    ],
    3: [
      {
        'titre': 'Approfondissement',
        'etoiles': 3,
        'enonce':
            'Ces questions évaluent votre compréhension plus approfondie.',
        'questions': [
          {
            'text': 'Quelle était la puissance coloniale principale ?',
            'type': 'texte',
            'reponse': 'France',
            'points': 2,
          },
          {
            'text': 'Quel est le rôle de l’ONU dans l’indépendance ?',
            'type': 'texte',
            'reponse': 'Supervision',
            'points': 3,
          }
        ],
      },
    ],
  };

  Widget _etoiles(int n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < n ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        ),
      ),
    );
  }

  void _autoEvaluerExercice(int index, Map exercice) {
    int score = 0;
    int total = 0;

    for (var q in exercice['questions']) {
      final bonne = q['reponse'].toString().toLowerCase().trim();
      final user =
          reponsesDonnees[q['text']]?.toLowerCase().trim() ?? '';
      final pts = q['points'] as int;

      total += pts;
      if (user == bonne) score += pts;

      corrections[q['text']] = bonne;
    }

    evalExerciceFaite[index] = true;

    historiqueEvaluations.add({
      'titre': exercice['titre'],
      'etoiles': exercice['etoiles'],
      'score': "$score / $total",
      'date': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Auto-évaluation : $score / $total"),
      backgroundColor: Colors.teal,
    ));

    setState(() {});
  }

  void _showHistorique() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Historique des évaluations",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xff03224C)),
            ),
            const SizedBox(height: 16),
            if (historiqueEvaluations.isEmpty)
              const Text("Aucune évaluation effectuée.",
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ...historiqueEvaluations.map((h) {
              final d = h['date'] as DateTime;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(h['titre']),
                subtitle: Row(
                  children: [
                    _etoiles(h['etoiles']),
                    const SizedBox(width: 8),
                    Text("Score : ${h['score']}"),
                  ],
                ),
                trailing: Text(
                  "${d.day.toString().padLeft(2, '0')}/"
                  "${d.month.toString().padLeft(2, '0')} "
                  "${d.hour.toString().padLeft(2, '0')}:"
                  "${d.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercices = etoileFiltre == 0
        ? exercicesParEtoiles.entries.expand((e) => e.value).toList()
        : exercicesParEtoiles[etoileFiltre] ?? [];

    return Column(
      children: [
        // ===== BARRE SUPÉRIEURE =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              DropdownButton<int>(
                value: etoileFiltre,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Toutes ⭐")),
                  DropdownMenuItem(value: 2, child: Text("★★")),
                  DropdownMenuItem(value: 3, child: Text("★★★")),
                ],
                onChanged: (v) => setState(() => etoileFiltre = v!),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showHistorique,
                icon: const Icon(Icons.history),
                tooltip: "Historique",
              ),
            ],
          ),
        ),

        // ===== EXERCICES =====
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exercices.length,
            itemBuilder: (context, index) {
              final ex = exercices[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITRE + ÉTOILES
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ex['titre'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff03224C)),
                        ),
                      ),
                      _etoiles(ex['etoiles']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ex['enonce']),
                  const SizedBox(height: 20),

                  ...ex['questions'].map<Widget>((q) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q['text'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (q['type'] == 'qcm')
                            ...q['choix'].map<Widget>((opt) {
                              return RadioListTile(
                                dense: true,
                                value: opt,
                                groupValue:
                                    reponsesDonnees[q['text']],
                                onChanged: (v) => setState(() =>
                                    reponsesDonnees[q['text']] = v!),
                                title: Text(opt),
                              );
                            }).toList()
                          else
                            TextField(
                              onChanged: (v) =>
                                  reponsesDonnees[q['text']] = v,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Color(0xffF4F6F8),
                                hintText: "Votre réponse",
                                border: InputBorder.none,
                              ),
                            ),
                          if (corrections.containsKey(q['text']))
                            Text(
                              "Correction : ${corrections[q['text']]}",
                              style:
                                  const TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    );
                  }),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () =>
                          _autoEvaluerExercice(index, ex),
                      child: const Text("Auto-évaluer"),
                    ),
                  ),

                  // LIGNE DE SÉPARATION DISCRÈTE
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
