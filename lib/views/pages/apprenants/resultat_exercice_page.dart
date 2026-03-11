import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/form_question_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────
const String _base    = 'https://yeki.pythonanywhere.com/api';
const Color _teal     = Color(0xFF008088);
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF5F7FA);
const Color _violet   = Color(0xFF6A1B9A);  // Couleur exercice dans le forum

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ─────────────────────────────────────────────────────────────────
// PAGE RÉSULTAT EXERCICE — dynamique
// Affiche la correction et permet de poser une question dans le forum
// ─────────────────────────────────────────────────────────────────
class ResultatExercicePage extends StatefulWidget {
  final int    exerciceId;
  final String exerciceTitre;
  final int?   coursId;
  final String coursTitre;

  const ResultatExercicePage({
    super.key,
    required this.exerciceId,
    required this.exerciceTitre,
    this.coursId,
    this.coursTitre = '',
  });

  @override
  State<ResultatExercicePage> createState() => _ResultatExercicePageState();
}

class _ResultatExercicePageState extends State<ResultatExercicePage>
    with SingleTickerProviderStateMixin {
  bool   _loading = true;
  Map?   _data;
  bool   _correctionVisible = false;

  late AnimationController _celebCtrl;
  late Animation<double>   _celebAnim;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
        Uri.parse('$_base/exercices/${widget.exerciceId}/resultat/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        setState(() {
          _data    = jsonDecode(res.body);
          _loading = false;
        });
        _celebCtrl.forward();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _ouvrirQuestionForum() {
    ouvrirQuestionForum(
      context,
      source:        'exercice',
      exerciceId:    widget.exerciceId,
      exerciceTitre: widget.exerciceTitre,
      coursId:       widget.coursId,
      coursTitre:    widget.coursTitre,
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
        title: Text(widget.exerciceTitre,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: _dark)),
        actions: [
          // Bouton question forum dans la AppBar
          TextButton.icon(
            onPressed: _ouvrirQuestionForum,
            icon: const Icon(Icons.help_outline_rounded,
                color: _violet, size: 18),
            label: const Text('Question',
                style: TextStyle(color: _violet, fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _data == null
              ? const Center(child: Text('Résultat indisponible'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final note      = _data!['note'];
    final noteSur   = _data!['note_sur'];
    final details   = _data!['detail'] as List? ?? [];
    final bonnes    = details.where((d) => d['correct'] == true).length;
    final total     = details.length;
    final scoreRatio = total > 0 ? bonnes / total : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Carte score avec animation ────────────────────────
        ScaleTransition(
          scale: _celebAnim,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: scoreRatio >= 0.5
                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                    : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Icon(
                scoreRatio >= 0.5 ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                scoreRatio >= 0.5 ? 'Bravo !' : 'Continuez !',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              if (note != null)
                Text('$note / $noteSur',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 48,
                        fontWeight: FontWeight.w900))
              else
                Text('$bonnes / $total',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 48,
                        fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                '$bonnes bonne${bonnes > 1 ? 's' : ''} réponse${bonnes > 1 ? 's' : ''} sur $total',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // ── Bannière "Poser une question" ─────────────────────
        _buildQuestionBanner(),

        const SizedBox(height: 24),

        // ── Bouton voir la correction ─────────────────────────
        GestureDetector(
          onTap: () => setState(() => _correctionVisible = !_correctionVisible),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _teal.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.list_alt_rounded, color: _teal, size: 20),
              const SizedBox(width: 12),
              const Text('Voir la correction détaillée',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
              const Spacer(),
              Icon(
                _correctionVisible ? Icons.expand_less : Icons.expand_more,
                color: _teal),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // ── Détail questions ──────────────────────────────────
        if (_correctionVisible)
          ...details.asMap().entries.map((e) =>
              _buildDetailQuestion(e.key, e.value)),

        const SizedBox(height: 30),
      ],
    );
  }

  // ── Bannière "Poser une question" ─────────────────────────────
  Widget _buildQuestionBanner() => GestureDetector(
    onTap: _ouvrirQuestionForum,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_violet.withOpacity(0.08), _violet.withOpacity(0.04)],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _violet.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _violet.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.help_outline_rounded, color: _violet, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Une question sur cet exercice ?',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: _dark)),
            const SizedBox(height: 2),
            Text('Posez-la dans le forum — votre professeur répond sous 24h',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: _violet, borderRadius: BorderRadius.circular(10)),
          child: const Text('Demander',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    ),
  );

  // ── Détail d'une question ─────────────────────────────────────
  Widget _buildDetailQuestion(int idx, Map d) {
    final isCorrect = d['correct'] == true;
    final color     = isCorrect ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Question ${idx + 1}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 10),
        Text(d['question'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _dark, height: 1.4)),
        const SizedBox(height: 10),
        if (d['reponse_utilisateur'] != null) ...[
          _reponseRow('Votre réponse', d['reponse_utilisateur'], isCorrect ? Colors.green : Colors.red),
        ],
        if (!isCorrect && d['bonne_reponse'] != null) ...[
          const SizedBox(height: 6),
          _reponseRow('Bonne réponse', d['bonne_reponse'], Colors.green),
        ],
        if (d['explication'] != null && d['explication'].toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 15, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(d['explication'],
                    style: TextStyle(
                        fontSize: 12, color: Colors.blue.shade800, height: 1.4)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _reponseRow(String label, String valeur, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label : ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      Expanded(
        child: Text(valeur,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ],
  );
}
