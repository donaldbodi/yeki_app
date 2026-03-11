import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PasserExercicePage extends StatefulWidget {
  final int exerciceId;
  const PasserExercicePage({super.key, required this.exerciceId});

  @override
  State<PasserExercicePage> createState() => _PasserExercicePageState();
}

class _PasserExercicePageState extends State<PasserExercicePage> {
  // --- Couleurs Thème Yéki ---
  final Color primaryColor = const Color(0xFF2884A0);
  final Color darkBlue = const Color(0xFF1A1C1E);
  final Color bgColor = const Color(0xFFF8FAFB);

  Map<String, dynamic> exercice = {};
  bool loading = true;
  int tempsRestant = 0;
  int tempsTotal = 0;
  Timer? timer;
  bool submitting = false;
  final Map<int, String> reponses = {};

  @override
  void initState() {
    super.initState();
    demarrerEtCharger();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> demarrerEtCharger() async {
    try {
      final token = await getToken();
      final headers = {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Token $token",
      };

      // Démarrer la session
      await http.post(
        Uri.parse("https://yekiapp.pythonanywhere.com/api/exercices/${widget.exerciceId}/demarrer/"),
        headers: headers,
      );

      // Charger l'exercice
      final res = await http.get(
        Uri.parse("https://yekiapp.pythonanywhere.com/api/exercices/${widget.exerciceId}/"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        exercice = jsonDecode(res.body);
        tempsRestant = (exercice['temps_restant'] as num?)?.toInt() ?? 0;
        tempsTotal = (exercice['duree'] ?? 0) * 60; // Supposant que durée est en minutes
        if (tempsRestant > 0) startTimer();
      }
    } catch (e) {
      debugPrint("Erreur : $e");
    }
    if (mounted) setState(() => loading = false);
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (tempsRestant <= 0) {
        t.cancel();
        soumettre(auto: true);
      } else {
        setState(() => tempsRestant--);
      }
    });
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> soumettre({bool auto = false}) async {
    if (submitting) return;
    setState(() => submitting = true);
    timer?.cancel();
    // Logique API identique...
    // (Conserve ton code de soumission ici)
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final List questions = exercice['questions'] ?? [];
    double progress = questions.isEmpty ? 0 : reponses.length / questions.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercice['titre'] ?? "Examen", 
                 style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            Text("${reponses.length}/${questions.length} questions répondues",
                 style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          ],
        ),
        actions: [_buildTimerBadge()],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: primaryColor.withOpacity(0.1),
            color: primaryColor,
            minHeight: 6,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeaderEnonce(),
                const SizedBox(height: 25),
                ...questions.asMap().entries.map((entry) {
                  return _buildQuestionCard(entry.value, entry.key + 1);
                }),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPOSANTS UI ---

  Widget _buildTimerBadge() {
    bool isUrgent = tempsRestant < 60; // Moins d'une minute
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.redAccent : primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              formatTime(tempsRestant),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderEnonce() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text("Consigne", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Text(
            exercice['enonce'] ?? "Lisez attentivement les questions suivantes.",
            style: TextStyle(color: darkBlue.withOpacity(0.8), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    final int qId = q['id'];
    final String type = q['type'] ?? "texte";
    final List choix = q['choix'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primaryColor,
                child: Text("$index", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q['text'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (type == "qcm")
            ...choix.map((c) => _buildOption(qId, c.toString()))
          else
            TextField(
              onChanged: (v) => setState(() => reponses[qId] = v),
              decoration: InputDecoration(
                hintText: "Saisissez votre réponse ici...",
                fillColor: bgColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(int qId, String text) {
    bool isSelected = reponses[qId] == text;
    return GestureDetector(
      onTap: () => setState(() => reponses[qId] = text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, 
                style: TextStyle(
                  color: isSelected ? primaryColor : darkBlue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: submitting ? null : () => soumettre(),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: submitting
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Terminer l'examen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}