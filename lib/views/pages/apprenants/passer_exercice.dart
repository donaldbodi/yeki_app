// lib/views/pages/apprenants/passer_exercice_page.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/resultat_exercice_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';

class PasserExercicePage extends StatefulWidget {
  final int exerciceId;
  final int? coursId;
  final String coursTitre;

  const PasserExercicePage({
    super.key,
    required this.exerciceId,
    required this.coursId,
    required this.coursTitre,
  });

  @override
  State<PasserExercicePage> createState() => _PasserExercicePageState();
}

class _PasserExercicePageState extends State<PasserExercicePage> {
  final Color primaryColor = const Color(0xFF2884A0);
  final Color darkBlue = const Color(0xFF1A1C1E);
  final Color bgColor = const Color(0xFFF8FAFB);
  final Color greenColor = const Color(0xFF10B981);
  final Color orangeColor = const Color(0xFFF97316);
  final Color redColor = const Color(0xFFEF4444);
  final Color violetColor = const Color(0xFF6A1B9A);

  Map<String, dynamic> exercice = {};
  bool loading = true;
  bool submitted = false;
  int tempsRestant = 0;
  int dureeTotale = 0;
  int tentativesRestantes = 0;
  int tentativesMax = 1;
  bool tentativesEpuisees = false;
  Timer? timer;
  bool submitting = false;
  final Map<int, String> reponses = {};
  Map<String, dynamic>? resultat;
  bool showCorrection = false;

  @override
  void initState() {
    super.initState();
    demarrerEtCharger();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> demarrerEtCharger() async {
    try {
      final token = await getToken();
      if (token == null) {
        _showSnackbar("Veuillez vous reconnecter", error: true);
        setState(() => loading = false);
        return;
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      };

      // Étape 1: Démarrer la session
      final startRes = await http.post(
        Uri.parse("https://yeki.pythonanywhere.com/api/exercices/${widget.exerciceId}/demarrer/"),
        headers: headers,
      );

      if (startRes.statusCode == 200) {
        final startData = jsonDecode(startRes.body);
        tempsRestant = _toInt(startData['temps_restant']);
        dureeTotale = _toInt(startData['duree_totale']);
        tentativesRestantes = _toInt(startData['tentatives_restantes']);
        tentativesMax = _toInt(startData['tentatives_max']) ?? 1;
        
        debugPrint("Démarrage réussi - tempsRestant: $tempsRestant, tentativesRestantes: $tentativesRestantes");
      } else if (startRes.statusCode == 403) {
        // Tentatives épuisées
        final errorData = jsonDecode(startRes.body);
        tentativesEpuisees = true;
        _showSnackbar(errorData['detail'] ?? "Nombre maximum de tentatives atteint", error: true);
        setState(() => loading = false);
        return;
      }

      // Étape 2: Charger le contenu de l'exercice
      final exoRes = await http.get(
        Uri.parse("https://yeki.pythonanywhere.com/api/exercices/${widget.exerciceId}/"),
        headers: headers,
      );

      if (exoRes.statusCode == 200) {
        exercice = jsonDecode(exoRes.body);
        
        if (dureeTotale == 0) {
          if (exercice['duree_totale'] != null) {
            dureeTotale = _toInt(exercice['duree_totale']);
          } else if (exercice['duree_minutes'] != null) {
            dureeTotale = _toInt(exercice['duree_minutes']) * 60;
          }
        }
        
        if (tempsRestant == 0 && dureeTotale > 0 && !tentativesEpuisees) {
          tempsRestant = dureeTotale;
          startTimer();
        }
        
        // Si tentatives épuisées, récupérer le dernier résultat
        if (tentativesEpuisees) {
          await _recupererDernierResultat(token);
        }
      } else {
        _showSnackbar("Erreur chargement de l'exercice", error: true);
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      _showSnackbar("Erreur de connexion: ${e.toString()}", error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _recupererDernierResultat(String token) async {
    try {
      final res = await http.get(
        Uri.parse("https://yeki.pythonanywhere.com/api/evaluations/exercice/${widget.exerciceId}/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          resultat = data;
          submitted = true;
          showCorrection = true;
        });
      }
    } catch (e) {
      debugPrint("Erreur récupération résultat: $e");
    }
  }

  void startTimer() {
    if (tentativesEpuisees) return;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (tempsRestant <= 0) {
        t.cancel();
        soumettre(auto: true);
      } else {
        if (mounted) setState(() => tempsRestant--);
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds < 0) seconds = 0;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> soumettre({bool auto = false}) async {
    if (submitting || tentativesEpuisees) return;
    setState(() => submitting = true);
    timer?.cancel();

    final token = await getToken();
    if (token == null) {
      setState(() => submitting = false);
      _showSnackbar("Veuillez vous reconnecter.", error: true);
      return;
    }

    final questions = exercice['questions'] ?? [];
    final toutesRepondues = reponses.length == questions.length;
    
    if (!toutesRepondues && !auto) {
      final nonRepondues = questions.length - reponses.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Attention"),
          content: Text("Vous n'avez pas répondu à $nonRepondues question(s).\nVoulez-vous vraiment soumettre ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Soumettre", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) {
        setState(() => submitting = false);
        startTimer();
        return;
      }
    }

    try {
      final Map<String, String> reponsesString = reponses.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final response = await http.post(
        Uri.parse("https://yeki.pythonanywhere.com/api/exercices/${widget.exerciceId}/evaluer/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"reponses": reponsesString}),
      );

      debugPrint("Soumission - status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          resultat = data;
          submitted = true;
          submitting = false;
          showCorrection = true;
        });

        _showSnackbar(
          auto ? "⏰ Temps écoulé ! Exercice soumis automatiquement." : "✓ Exercice soumis avec succès !",
          error: false,
        );
      } else {
        setState(() => submitting = false);
        try {
          final errorData = jsonDecode(response.body);
          _showSnackbar(errorData['detail'] ?? "Erreur lors de la soumission", error: true);
        } catch (_) {
          _showSnackbar("Erreur ${response.statusCode}", error: true);
        }
      }
    } catch (e) {
      debugPrint("Erreur soumission: $e");
      setState(() => submitting = false);
      _showSnackbar("Erreur réseau: ${e.toString()}", error: true);
    }
  }

  void _showSnackbar(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? redColor : greenColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _voirResultats() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatExercicePage(
          exerciceId: widget.exerciceId,
          exerciceTitre: exercice['titre'] ?? 'Exercice',
          coursId: widget.coursId,
          coursTitre: widget.coursTitre,
        ),
      ),
    );
  }

  void _ouvrirPreoccupation() {
    ouvrirPreoccupation(
      context: context,
      source: 'exercice',
      exerciceId: widget.exerciceId,
      exerciceTitre: exercice['titre'] ?? 'Exercice',
      coursId: widget.coursId,
      coursTitre: widget.coursTitre,
    );
  }

  void _ouvrirIA() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YekiIAChatPage(
          coursId: widget.coursId ?? 0,
          coursTitre: widget.coursTitre,
          sourceInitiale: 'exercice',
          sourceId: widget.exerciceId,
          sourceTitreInit: exercice['titre'] ?? 'Exercice',
        ),
      ),
    );
  }

  void _retour() {
    timer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                "Chargement de l'exercice...",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Affichage du résultat si tentatives épuisées ou déjà soumis
    if ((tentativesEpuisees || submitted) && resultat != null) {
      return _buildResultView();
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
          onPressed: _retour,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercice['titre'] ?? "Examen",
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              "${reponses.length}/${questions.length} questions répondues",
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          _buildTimerBadge(),
          IconButton(
            icon: const Icon(Icons.psychology_rounded, color: Colors.white),
            onPressed: _ouvrirIA,
            tooltip: "Yéki IA",
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _ouvrirPreoccupation,
            tooltip: "Poser une question",
          ),
        ],
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

  Widget _buildResultView() {
    final note = _toDouble(resultat!['note']) != 0 
        ? _toDouble(resultat!['note']) 
        : _toDouble(resultat!['score']);
    final noteSur = _toDouble(resultat!['note_sur']) != 0 
        ? _toDouble(resultat!['note_sur']) 
        : _toDouble(resultat!['total']);
    final details = resultat!['detail'] as List? ?? [];
    
    // Calculer les points réels
    double totalPoints = 0;
    double pointsObtenus = 0;
    for (var d in details) {
      final pointsMax = _toDouble(d['points_max']);
      totalPoints += pointsMax;
      if (d['correct'] == true) {
        pointsObtenus += pointsMax;
      }
    }
    
    final bonnes = details.where((d) => d['correct'] == true).length;
    final total = details.length;
    final scorePercent = totalPoints > 0 ? (pointsObtenus / totalPoints) : 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _retour,
        ),
        title: const Text("Résultat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _voirResultats,
            icon: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 18),
            label: const Text("Détails", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: scorePercent >= 0.5
                      ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                      : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    scorePercent >= 0.5 ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    scorePercent >= 0.5 ? 'Bravo !' : tentativesEpuisees ? 'Tentatives épuisées' : 'Continuez vos efforts !',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pointsObtenus.toStringAsFixed(1)} / ${totalPoints.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note : ${note.toStringAsFixed(1)} / ${noteSur.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$bonnes bonne${bonnes > 1 ? 's' : ''} réponse${bonnes > 1 ? 's' : ''} sur $total',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  if (tentativesEpuisees)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Maximum de tentatives atteint',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildIABanner(),
            const SizedBox(height: 12),
            _buildPreoccupationBanner(),
            const SizedBox(height: 20),
            if (details.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => showCorrection = !showCorrection),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Voir la correction détaillée',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: darkBlue),
                      ),
                      const Spacer(),
                      Icon(showCorrection ? Icons.expand_less : Icons.expand_more, color: primaryColor),
                    ],
                  ),
                ),
              ),
            if (showCorrection)
              ...details.asMap().entries.map((e) => _buildDetailQuestion(e.key, e.value)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _voirResultats,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text("Voir les résultats complets"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIABanner() => GestureDetector(
    onTap: _ouvrirIA,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(Icons.psychology_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posez une question à Yéki IA',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: darkBlue),
                ),
                const SizedBox(height: 2),
                Text(
                  'Obtenez des explications personnalisées sur cet exercice',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Discuter',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPreoccupationBanner() => GestureDetector(
    onTap: _ouvrirPreoccupation,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orangeColor.withOpacity(0.08), orangeColor.withOpacity(0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: orangeColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(Icons.help_outline_rounded, color: orangeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une préoccupation sur cet exercice ?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: darkBlue),
                ),
                const SizedBox(height: 2),
                Text(
                  'Posez-la dans le forum — votre professeur répond sous 24h',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: orangeColor, borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Forum',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDetailQuestion(int idx, Map d) {
    final isCorrect = d['correct'] == true;
    final color = isCorrect ? greenColor : redColor;
    final pointsMax = _toDouble(d['points_max']);
    final pointsObtenus = _toDouble(d['points_obtenus']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Question ${idx + 1}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pointsObtenus.toStringAsFixed(0)} / ${pointsMax.toStringAsFixed(0)} pts',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            d['question'] ?? '',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkBlue, height: 1.4),
          ),
          const SizedBox(height: 10),
          if (d['reponse_utilisateur'] != null && d['reponse_utilisateur'].toString().isNotEmpty)
            _reponseRow('Votre réponse', d['reponse_utilisateur'].toString(), isCorrect ? greenColor : redColor),
          if (!isCorrect && d['bonne_reponse'] != null && d['bonne_reponse'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            _reponseRow('Bonne réponse', d['bonne_reponse'].toString(), greenColor),
          ],
          if (d['explication'] != null && d['explication'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 15, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d['explication'],
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reponseRow(String label, String valeur, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label : ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        Expanded(
          child: Text(
            valeur,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    ),
  );

  Widget _buildTimerBadge() {
    if (tentativesEpuisees) return const SizedBox.shrink();
    bool isUrgent = tempsRestant < 60 && tempsRestant > 0;
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
          if (!tentativesEpuisees && tentativesRestantes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Tentatives restantes : $tentativesRestantes / $tentativesMax",
                style: TextStyle(fontSize: 12, color: primaryColor),
              ),
            ),
          if (tentativesEpuisees)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: redColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: redColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: redColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "Vous avez utilisé toutes vos tentatives",
                      style: TextStyle(fontSize: 12, color: redColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${_toInt(q['points'])} pt",
                  style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
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
              maxLines: 3,
              enabled: !tentativesEpuisees,
              decoration: InputDecoration(
                hintText: tentativesEpuisees ? "Tentatives épuisées" : "Saisissez votre réponse ici...",
                fillColor: bgColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
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
      onTap: tentativesEpuisees ? null : () => setState(() => reponses[qId] = text),
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
              child: Text(
                text,
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
    if (tentativesEpuisees) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _voirResultats,
          icon: const Icon(Icons.assignment_turned_in),
          label: const Text("Voir les résultats"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );
    }

    final questions = exercice['questions'] ?? [];
    final toutesRepondues = reponses.length == questions.length;

    return Column(
      children: [
        if (!toutesRepondues && questions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "${questions.length - reponses.length} question(s) restante(s)",
              style: TextStyle(fontSize: 12, color: orangeColor, fontWeight: FontWeight.w600),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitting ? null : () => soumettre(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    "Terminer l'examen",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}