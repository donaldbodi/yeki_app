// lib/views/pages/apprenants/passer_exercice.dart
// ═══════════════════════════════════════════════════════════════════════════
// PASSER UN EXERCICE — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/resultat_exercice_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

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
        if (mounted) {
          ErrorHandler.showError(context, "Veuillez vous reconnecter");
          setState(() => loading = false);
        }
        return;
      }

      final headers = ApiHeaders.auth(token);

      // Étape 1: Démarrer la session
      final startRes = await http.post(
        Uri.parse(ApiConstants.exerciceDemarrer(widget.exerciceId)),
        headers: headers,
      );

      if (startRes.statusCode == 200) {
        final startData = jsonDecode(startRes.body);
        tempsRestant = _toInt(startData['temps_restant']);
        dureeTotale = _toInt(startData['duree_totale']);
        tentativesRestantes = _toInt(startData['tentatives_restantes']);
        tentativesMax = _toInt(startData['tentatives_max']);
      } else if (startRes.statusCode == 403) {
        final errorData = jsonDecode(startRes.body);
        tentativesEpuisees = true;
        if (mounted) {
          ErrorHandler.showError(context, errorData['detail'] ?? "Nombre maximum de tentatives atteint");
          setState(() => loading = false);
        }
        return;
      }

      // Étape 2: Charger le contenu de l'exercice
      final exoRes = await http.get(
        Uri.parse(ApiConstants.exerciceDetail(widget.exerciceId)),
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
        
        if (tentativesEpuisees) {
          await _recupererDernierResultat(token);
        }
      } else {
        if (mounted) {
          ErrorHandler.showError(context, "Erreur chargement de l'exercice");
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      if (mounted) {
        ErrorHandler.showError(context, "Erreur de connexion: ${e.toString()}");
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _recupererDernierResultat(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.resultatExercice(widget.exerciceId)),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
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
      if (mounted) {
        ErrorHandler.showError(context, "Veuillez vous reconnecter.");
      }
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
          backgroundColor: YekiColors.white,
          title: const Text("Attention"),
          content: Text("Vous n'avez pas répondu à $nonRepondues question(s).\nVoulez-vous vraiment soumettre ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annuler", style: TextStyle(color: YekiColors.textMedium)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: YekiColors.primaryDark),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Soumettre", style: TextStyle(color: YekiColors.white)),
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
        Uri.parse(ApiConstants.exerciceEvaluer(widget.exerciceId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({"reponses": reponsesString}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          resultat = data;
          submitted = true;
          submitting = false;
          showCorrection = true;
        });

        ErrorHandler.showSuccess(
          context,
          auto ? "⏰ Temps écoulé ! Exercice soumis automatiquement." : "✓ Exercice soumis avec succès !",
        );
      } else {
        setState(() => submitting = false);
        if (mounted) {
          try {
            final errorData = jsonDecode(response.body);
            ErrorHandler.showError(context, errorData['detail'] ?? "Erreur lors de la soumission");
          } catch (_) {
            ErrorHandler.showError(context, "Erreur ${response.statusCode}");
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur soumission: $e");
      setState(() => submitting = false);
      if (mounted) {
        ErrorHandler.showError(context, "Erreur réseau: ${e.toString()}");
      }
    }
  }

  void _voirResultats() {
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YekiLoader(),
              const SizedBox(height: 16),
              Text("Chargement de l'exercice...", style: TextStyle(color: YekiColors.textLight)),
            ],
          ),
        ),
      );
    }

    if ((tentativesEpuisees || submitted) && resultat != null) {
      return _buildResultView();
    }

    final List questions = exercice['questions'] ?? [];
    double progress = questions.isEmpty ? 0 : reponses.length / questions.length;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: YekiColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: YekiColors.white),
          onPressed: _retour,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercice['titre'] ?? "Examen",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "${reponses.length}/${questions.length} questions répondues",
              style: TextStyle(fontSize: 12, color: YekiColors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          _buildTimerBadge(),
          IconButton(
            icon: const Icon(Icons.psychology_rounded),
            onPressed: _ouvrirIA,
            tooltip: "Yéki IA",
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _ouvrirPreoccupation,
            tooltip: "Poser une question",
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
            color: YekiColors.primaryDark,
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
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: YekiColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retour,
        ),
        title: const Text("Résultat", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _voirResultats,
            icon: const Icon(Icons.assignment_turned_in, size: 18),
            label: const Text("Détails"),
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
                    color: YekiColors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    scorePercent >= 0.5 ? 'Bravo !' : tentativesEpuisees ? 'Tentatives épuisées' : 'Continuez vos efforts !',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pointsObtenus.toStringAsFixed(1)} / ${totalPoints.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: YekiColors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note : ${note.toStringAsFixed(1)} / ${noteSur.toStringAsFixed(0)}',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$bonnes bonne${bonnes > 1 ? 's' : ''} réponse${bonnes > 1 ? 's' : ''} sur $total',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  if (tentativesEpuisees)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: YekiColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Maximum de tentatives atteint',
                          style: TextStyle(color: YekiColors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                    color: YekiColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: YekiColors.primaryDark, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Voir la correction détaillée',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const Spacer(),
                      Icon(showCorrection ? Icons.expand_less : Icons.expand_more, color: YekiColors.primaryDark),
                    ],
                  ),
                ),
              ),
            if (showCorrection)
              ...details.asMap().entries.map((e) => _buildDetailQuestion(e.key, e.value)),
            const SizedBox(height: 30),
            YekiButton(
              label: "Voir les résultats complets",
              icon: Icons.assignment_turned_in,
              onPressed: _voirResultats,
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
          colors: [YekiColors.primaryDark.withValues(alpha: 0.08), YekiColors.primaryDark.withValues(alpha: 0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: YekiColors.primaryDark.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.psychology_rounded, color: YekiColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Posez une question à Yéki IA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Obtenez des explications personnalisées sur cet exercice', style: TextStyle(fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: YekiColors.primaryDark, borderRadius: BorderRadius.circular(8)),
            child: const Text('Discuter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
          colors: [YekiColors.warning.withValues(alpha: 0.08), YekiColors.warning.withValues(alpha: 0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: YekiColors.warning.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.help_outline_rounded, color: YekiColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Une préoccupation sur cet exercice ?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Posez-la dans le forum — votre professeur répond sous 24h', style: TextStyle(fontSize: 12, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: YekiColors.warning, borderRadius: BorderRadius.circular(8)),
            child: const Text('Forum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    ),
  );

  Widget _buildDetailQuestion(int idx, Map d) {
    final isCorrect = d['correct'] == true;
    final color = isCorrect ? YekiColors.success : YekiColors.error;
    final pointsMax = _toDouble(d['points_max']);
    final pointsObtenus = _toDouble(d['points_obtenus']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: YekiShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Question ${idx + 1}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pointsObtenus.toStringAsFixed(0)} / ${pointsMax.toStringAsFixed(0)} pts',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(d['question'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 10),
          if (d['reponse_utilisateur'] != null && d['reponse_utilisateur'].toString().isNotEmpty)
            _reponseRow('Votre réponse', d['reponse_utilisateur'].toString(), isCorrect ? YekiColors.success : YekiColors.error),
          if (!isCorrect && d['bonne_reponse'] != null && d['bonne_reponse'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            _reponseRow('Bonne réponse', d['bonne_reponse'].toString(), YekiColors.success),
          ],
          if (d['explication'] != null && d['explication'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: YekiColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 15, color: YekiColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(d['explication'], style: TextStyle(fontSize: 12, height: 1.4)),
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
        Text('$label : ', style: TextStyle(fontSize: 12, color: YekiColors.textLight)),
        Expanded(
          child: Text(valeur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
        color: isUrgent ? YekiColors.error : YekiColors.primaryDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: YekiColors.white),
            const SizedBox(width: 5),
            Text(formatTime(tempsRestant), style: const TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderEnonce() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: YekiColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              const Text("Consigne", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Text(
            exercice['enonce'] ?? "Lisez attentivement les questions suivantes.",
            style: const TextStyle(height: 1.5),
          ),
          if (!tentativesEpuisees && tentativesRestantes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Tentatives restantes : $tentativesRestantes / $tentativesMax",
                  style: TextStyle(fontSize: 12, color: YekiColors.primaryDark)),
            ),
          if (tentativesEpuisees)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: YekiColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: YekiColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: YekiColors.error, size: 14),
                    const SizedBox(width: 6),
                    Text("Vous avez utilisé toutes vos tentatives",
                        style: TextStyle(fontSize: 12, color: YekiColors.error, fontWeight: FontWeight.w600)),
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
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: YekiShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: YekiColors.primaryDark,
                child: Text("$index", style: const TextStyle(color: YekiColors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(q['text'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YekiColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("${_toInt(q['points'])} pt",
                    style: TextStyle(fontSize: 11, color: YekiColors.primaryDark, fontWeight: FontWeight.w600)),
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
                fillColor: YekiColors.backgroundLight,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5),
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
          color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? YekiColors.primaryDark : YekiColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? YekiColors.primaryDark : YekiColors.textLight,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: isSelected ? YekiColors.primaryDark : YekiColors.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (tentativesEpuisees) {
      return YekiButton(
        label: "Voir les résultats",
        icon: Icons.assignment_turned_in,
        onPressed: _voirResultats,
      );
    }

    final questions = exercice['questions'] ?? [];
    final toutesRepondues = reponses.length == questions.length;

    return Column(
      children: [
        if (!toutesRepondues && questions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text("${questions.length - reponses.length} question(s) restante(s)",
                style: TextStyle(fontSize: 12, color: YekiColors.warning, fontWeight: FontWeight.w600)),
          ),
        YekiButton(
          label: "Terminer l'examen",
          onPressed: submitting ? null : () => soumettre(),
          isLoading: submitting,
        ),
      ],
    );
  }
}