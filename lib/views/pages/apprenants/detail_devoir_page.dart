import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailDevoirPage extends StatefulWidget {
  final int devoirId;
  final String titre;
  final bool tempsFini;
  final bool devoirRemis;
  final bool devoirCorrige;
  final String correcteur;

  const DetailDevoirPage({
    super.key,
    required this.devoirId,
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
  List<Map<String, dynamic>> exercices = [];
  Map<String, TextEditingController> textControllers = {};
  Map<String, String> selectedOptions = {};
  bool devoirSoumis = false;
  Map<String, dynamic>? correction;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDevoir();
  }

  Future<String?> getToken() async {
    // Retourne ton token ici
    return "TON_TOKEN_API";
  }

  Future<void> _chargerDevoir() async {
    setState(() => isLoading = true);
    final token = await getToken();
    final res = await http.get(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/devoirs/${widget.devoirId}/"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Token $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        exercices = List<Map<String, dynamic>>.from(data['exercices'] ?? []);
        correction = data['correction'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement : ${res.statusCode}")),
      );
    }
  }

  Future<void> _soumettreDevoir() async {
    final token = await getToken();
    final reponses = {};

    textControllers.forEach((key, ctrl) {
      reponses[key] = ctrl.text;
    });
    selectedOptions.forEach((key, val) {
      reponses[key] = val;
    });

    final res = await http.post(
      Uri.parse("https://yekiapp.pythonanywhere.com/api/devoirs/${widget.devoirId}/soumettre/"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Token $token",
      },
      body: jsonEncode({"reponses": reponses}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      setState(() => devoirSoumis = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Devoir soumis avec succès."), backgroundColor: Colors.teal),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de soumission : ${res.body}")),
      );
    }
  }

  Widget _buildQuestion(Map question, String key) {
    final bool lectureSeule = widget.tempsFini || widget.devoirRemis || devoirSoumis;

    if (question['type'] == 'text') {
      textControllers.putIfAbsent(key, () => TextEditingController());
      if (correction != null && correction![key] != null) {
        textControllers[key]?.text = correction![key];
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ${question['texte']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );
    } else if (question['type'] == 'qcm') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ${question['texte']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...question['options'].map<Widget>((opt) {
            final isCorrect = correction != null && opt == correction![key];
            return RadioListTile<String>(
              value: opt,
              groupValue: selectedOptions[key],
              onChanged: lectureSeule ? null : (val) => setState(() => selectedOptions[key] = val!),
              title: Text(opt),
              activeColor: isCorrect ? Colors.green : Colors.deepOrange,
              tileColor: isCorrect ? Colors.green.shade50 : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercice['titre'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03224C))),
            const SizedBox(height: 14),
            ...List.generate(exercice['questions'].length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildQuestion(exercice['questions'][i], 'exo$index-$i'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionWidget() {
    if (correction == null) return const SizedBox.shrink();

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
          Text("🧑‍🏫 Corrigé par : ${widget.correcteur}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 12),
          Text("✅ Résumé de la correction :", style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...correction!.entries.map((e) => Text("• ${e.key} : ${e.value}", style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool peutSoumettre = !(widget.tempsFini || widget.devoirRemis || devoirSoumis);
    final bool peutVoirCorrection = widget.devoirCorrige && (devoirSoumis || widget.devoirRemis || widget.tempsFini);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF03224C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (widget.tempsFini && !widget.devoirRemis)
                    _buildAlerte("⏰ Temps écoulé ! Vous ne pouvez plus répondre.", Colors.redAccent),
                  if (widget.devoirRemis && !widget.devoirCorrige)
                    _buildAlerte("📤 Devoir soumis. En attente de correction.", Colors.orange),
                  if (devoirSoumis) _buildAlerte("📩 Devoir envoyé avec succès.", Colors.green),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  if (peutVoirCorrection) _buildCorrectionWidget(),
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
          Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }
}