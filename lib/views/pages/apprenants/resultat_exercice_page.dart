// lib/views/pages/apprenants/resultat_exercice_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

const String _base = 'https://yeki.pythonanywhere.com/api';
const Color _teal = Color(0xFF008088);
const Color _dark = Color(0xFF0D1B2A);
const Color _bg = Color(0xFFF5F7FA);
const Color _violet = Color(0xFF6A1B9A);
const Color _green = Color(0xFF10B981);
//const Color _orange = Color(0xFFF97316);

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// Helper pour convertir en int en toute sécurité
/*int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}*/

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// ════════════════════════════════════════════════════════════════
// PAGE RÉSULTAT EXERCICE
// ════════════════════════════════════════════════════════════════
class ResultatExercicePage extends StatefulWidget {
  final int exerciceId;
  final String exerciceTitre;
  final int? coursId;
  final String coursTitre;
  final TabController? tabController;
  final int forumTabIndex;
  final void Function(int questionId)? onNaviguerForum;

  const ResultatExercicePage({
    super.key,
    required this.exerciceId,
    required this.exerciceTitre,
    this.coursId,
    this.coursTitre = '',
    this.onNaviguerForum,
    this.tabController,
    this.forumTabIndex = 3,
  });

  @override
  State<ResultatExercicePage> createState() => _ResultatExercicePageState();
}

class _ResultatExercicePageState extends State<ResultatExercicePage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map? _data;
  bool _correctionVisible = false;
  late AnimationController _celebCtrl;
  late Animation<double> _celebAnim;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _celebAnim = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);
    _charger();
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/evaluations/exercice/${widget.exerciceId}/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body);
          _loading = false;
        });
        _celebCtrl.forward();
      } else if (res.statusCode == 404) {
        setState(() => _loading = false);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _ouvrirPreoccupation() {
    ouvrirPreoccupation(
      context: context,
      source: 'exercice',
      exerciceId: widget.exerciceId,
      exerciceTitre: widget.exerciceTitre,
      coursId: widget.coursId,
      coursTitre: widget.coursTitre,
      tabController: widget.tabController,
      forumTabIndex: widget.forumTabIndex,
      onNaviguerForum: widget.onNaviguerForum,
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
          sourceTitreInit: widget.exerciceTitre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _dark),
        title: Text(
          widget.exerciceTitre,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _dark),
        ),
        actions: [
          TextButton.icon(
            onPressed: _ouvrirIA,
            icon: const Icon(Icons.psychology_rounded, color: _teal, size: 18),
            label: const Text('Yéki IA', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _ouvrirPreoccupation,
            icon: const Icon(Icons.help_outline_rounded, color: _violet, size: 18),
            label: const Text('Forum', style: TextStyle(color: _violet, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _data == null
              ? _buildEmptyState()
              : _buildBody(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat disponible',
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Faites l\'exercice pour voir votre résultat',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour à l\'exercice'),
            style: ElevatedButton.styleFrom(backgroundColor: _teal, elevation: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Récupérer les données avec conversion sécurisée
    final note = _toDouble(_data!['note']);
    final noteSur = _toDouble(_data!['note_sur']) != 0 ? _toDouble(_data!['note_sur']) : 20.0;
    final details = _data!['detail'] as List? ?? [];

    // Calculer le score total et les points obtenus
    double totalPoints = 0;
    double pointsObtenus = 0;

    for (var d in details) {
      final pointsMax = _toDouble(d['points_max']);
      totalPoints += pointsMax;
      if (d['correct'] == true) {
        pointsObtenus += pointsMax;
      }
    }

    // Calculer le pourcentage de réussite
    final scorePercent = totalPoints > 0 ? (pointsObtenus / totalPoints) : 0.0;
    final bonnes = details.where((d) => d['correct'] == true).length;
    final total = details.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Carte score animée avec points réels ─────────────────
        ScaleTransition(
          scale: _celebAnim,
          child: Container(
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
                  scorePercent >= 0.5 ? 'Bravo !' : 'Continuez vos efforts !',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
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
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Bannière Yéki IA ─────────────────────────────────────
        _buildIABanner(),

        const SizedBox(height: 12),

        // ── Bannière préoccupation forum ─────────────────────────
        _buildPreoccupationBanner(),

        const SizedBox(height: 24),

        // ── Bouton voir la correction ──────────────────────────
        if (details.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _correctionVisible = !_correctionVisible),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: _teal, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Voir la correction détaillée',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                  ),
                  const Spacer(),
                  Icon(_correctionVisible ? Icons.expand_less : Icons.expand_more, color: _teal),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        if (_correctionVisible && details.isNotEmpty)
          ...details.asMap().entries.map((e) => _buildDetailQuestion(e.key, e.value)),

        const SizedBox(height: 30),

        // ── Bouton refaire l'exercice ───────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refaire l\'exercice'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: _teal),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ── Bannière Yéki IA ─────────────────────────────────────────
  Widget _buildIABanner() => GestureDetector(
    onTap: _ouvrirIA,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal.withOpacity(0.08), _teal.withOpacity(0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _teal.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.psychology_rounded, color: _teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Posez une question à Yéki IA',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _dark),
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
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Discuter',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Bannière préoccupation forum ─────────────────────────────
  Widget _buildPreoccupationBanner() => GestureDetector(
    onTap: _ouvrirPreoccupation,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_violet.withOpacity(0.08), _violet.withOpacity(0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _violet.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _violet.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.help_outline_rounded, color: _violet, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Une préoccupation sur cet exercice ?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _dark),
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
            decoration: BoxDecoration(color: _violet, borderRadius: BorderRadius.circular(10)),
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
    final color = isCorrect ? _green : Colors.red;
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dark, height: 1.4),
          ),
          const SizedBox(height: 10),
          if (d['reponse_utilisateur'] != null && d['reponse_utilisateur'].toString().isNotEmpty)
            _reponseRow('Votre réponse', d['reponse_utilisateur'].toString(), isCorrect ? _green : Colors.red),
          if (!isCorrect && d['bonne_reponse'] != null && d['bonne_reponse'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            _reponseRow('Bonne réponse', d['bonne_reponse'].toString(), _green),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    ),
  );
}