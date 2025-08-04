import 'package:flutter/material.dart';

class DetailDevoirPage extends StatefulWidget {
  final String titre;
  final bool tempsFini;
  final bool devoirRemis;
  final bool devoirCorrige;
  final String correcteur;

  const DetailDevoirPage({
    super.key,
    required this.titre,
    required this.tempsFini,
    required this.devoirRemis,
    required this.devoirCorrige,
    required this.correcteur,
  });

  @override
  State<DetailDevoirPage> createState() => _DetailDevoirPageState();
}

class _DetailDevoirPageState extends State<DetailDevoirPage> {
  final List<Map<String, dynamic>> exercices = [
    {
      'titre': 'Exercice 1',
      'questions': [
        {'texte': 'Citez les trois états de la matière.', 'type': 'text'},
        {'texte': 'Quelle est la formule chimique du sel ?', 'type': 'text'},
      ],
    },
    {
      'titre': 'Exercice 2',
      'questions': [
        {
          'texte': 'Quelle est la capitale de l’Espagne ?',
          'type': 'qcm',
          'options': ['Madrid', 'Barcelone', 'Lisbonne'],
          'reponseCorrecte': 'Madrid',
        },
        {
          'texte': 'Combien font 9 x 6 ?',
          'type': 'qcm',
          'options': ['54', '56', '64'],
          'reponseCorrecte': '54',
        },
      ],
    },
  ];

  final Map<String, TextEditingController> textControllers = {};
  final Map<String, String> selectedOptions = {};
  bool devoirSoumis = false;

  void _soumettreDevoir() {
    setState(() => devoirSoumis = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ Devoir soumis avec succès."),
      backgroundColor: Colors.teal,
    ));
  }

  Widget _buildQuestion(Map question, String key) {
    final bool lectureSeule =
        widget.tempsFini || widget.devoirRemis || devoirSoumis;

    if (question['type'] == 'text') {
      textControllers.putIfAbsent(key, () => TextEditingController());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ${question['texte']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: textControllers[key],
            enabled: !lectureSeule,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Votre réponse ici...",
              filled: true,
              fillColor: lectureSeule ? Colors.grey[200] : Colors.orange[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );
    } else if (question['type'] == 'qcm') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ${question['texte']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...question['options'].map<Widget>((opt) {
            final isCorrect =
                widget.devoirCorrige && opt == question['reponseCorrecte'];
            return RadioListTile<String>(
              value: opt,
              groupValue: selectedOptions[key],
              onChanged: lectureSeule
                  ? null
                  : (val) => setState(() => selectedOptions[key] = val!),
              title: Text(opt),
              activeColor: isCorrect ? Colors.green : Colors.deepOrange,
              tileColor:
                  isCorrect ? Colors.green.shade50 : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildExercice(Map exercice, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercice['titre'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF03224C),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(exercice['questions'].length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child:
                    _buildQuestion(exercice['questions'][i], 'exo$index-$i'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🧑‍🏫 Corrigé par : ${widget.correcteur}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 12),
          const Text("✅ Résumé de la correction :",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            "• États : solide, liquide, gaz\n"
            "• Sel : NaCl\n"
            "• Capitale : Madrid\n"
            "• 9 x 6 = 54",
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          const Text("💬 Poser une question sur cette correction :",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: "Votre question ici...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send),
            label: const Text("Envoyer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool peutSoumettre =
        !(widget.tempsFini || widget.devoirRemis || devoirSoumis);
    final bool peutVoirCorrection =
        widget.devoirCorrige &&
        (devoirSoumis || widget.devoirRemis || widget.tempsFini);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03224C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (widget.tempsFini && !widget.devoirRemis)
              _buildAlerte("⏰ Temps écoulé ! Vous ne pouvez plus répondre.",
                  Colors.redAccent),
            if (widget.devoirRemis && !widget.devoirCorrige)
              _buildAlerte(
                  "📤 Devoir soumis. En attente de correction.", Colors.orange),
            if (devoirSoumis)
              _buildAlerte("📩 Devoir envoyé avec succès.", Colors.green),

            const SizedBox(height: 10),
            ...List.generate(exercices.length, (i) => _buildExercice(exercices[i], i)),
            const SizedBox(height: 20),
            if (peutSoumettre)
              ElevatedButton.icon(
                onPressed: _soumettreDevoir,
                icon: const Icon(Icons.send_rounded),
                label: const Text("Soumettre le devoir"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (peutVoirCorrection) _buildCorrection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerte(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          )
        ],
      ),
    );
  }
}
