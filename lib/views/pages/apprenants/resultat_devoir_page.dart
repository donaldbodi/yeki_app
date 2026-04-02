import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────
const String _base  = 'https://yeki.pythonanywhere.com/api';
const Color _teal   = Color(0xFF008088);
const Color _dark   = Color(0xFF1A1C1E);
const Color _bg     = Color(0xFFF5F7FA);
const Color _orange = Color(0xFFE65100);

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ─────────────────────────────────────────────────────────────────
// PAGE RÉSULTAT DEVOIR
// ─────────────────────────────────────────────────────────────────
class ResultatDevoirPage extends StatefulWidget {
  final int    devoirId;
  final String titre;
  final int?   coursId;
  final String coursTitre;
  final TabController? tabController;       // nouveau
  final int forumTabIndex;                  // nouveau

  /// Callback pour naviguer vers le forum depuis CoursDetailTabs
  final void Function(int questionId)? onNaviguerForum;

  const ResultatDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
    this.coursId,
    this.coursTitre = '',
    this.onNaviguerForum,
    this.tabController,
    this.forumTabIndex = 3,
  });

  @override
  State<ResultatDevoirPage> createState() => _ResultatDevoirPageState();
}

class _ResultatDevoirPageState extends State<ResultatDevoirPage> {
  bool _loading = true;
  Map? _data;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/devoirs/${widget.devoirId}/resultat/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /*Future<void> _ouvrirPreoccupation() async {
    await ouvrirPreoccupation(
      context,
      source:      'devoir',
      devoirId:    widget.devoirId,
      devoirTitre: widget.titre,
      coursId:     widget.coursId,
      coursTitre:  widget.coursTitre,
      onNaviguerForum: (questionId) {
        if (widget.onNaviguerForum != null) {
          widget.onNaviguerForum!(questionId);
          // Remonter jusqu'à CoursDetailTabs
          Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/cours-detail');
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => _ForumStandalone(scrollToQuestionId: questionId)));
        }
      },
    );
  }*/

  Future<void> _ouvrirPreoccupation() async {
    ouvrirPreoccupation(
      context: context,
      source: 'devoir',
      devoirId: widget.devoirId,
      devoirTitre: widget.titre,
      coursId: widget.coursId,
      coursTitre: widget.coursTitre,
      tabController: widget.tabController,
      forumTabIndex: widget.forumTabIndex,
      onNaviguerForum: widget.onNaviguerForum,
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
        title: Text(widget.titre,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _dark)),
        // actions: disabled for now
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _data == null
              ? const Center(child: Text('Résultat indisponible.'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final note       = _data!['note'];
    final noteSur    = _data!['note_sur'];
    final detail     = _data!['detail'] as List? ?? [];
    final retard     = _data!['en_retard'] == true;
    final estCorrige = note != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Carte score ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF00404A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            const Text('Votre résultat', style: TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 12),
            if (estCorrige)
              Text('$note / $noteSur',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900))
            else ...[
              const Icon(Icons.hourglass_top_rounded, color: Colors.white54, size: 40),
              const SizedBox(height: 8),
              const Text('En attente de correction', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
            if (retard)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(10)),
                child: const Text('Remis en retard', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Bannière préoccupation ─────────────────────────────
        _buildPreoccupationBanner(),

        const SizedBox(height: 20),

        // ── Commentaire enseignant ─────────────────────────────
        if (estCorrige && _data!['commentaire'] != null &&
            _data!['commentaire'].toString().isNotEmpty) ...[
          const Text("Commentaire de l'enseignant",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _dark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100)),
            child: Text(_data!['commentaire'], style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          const SizedBox(height: 24),
        ],

        // ── Détail questions ───────────────────────────────────
        if (estCorrige && detail.isNotEmpty) ...[
          const Text('Détail des réponses',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _dark)),
          const SizedBox(height: 12),
          ...detail.asMap().entries.map((e) => _buildReponseCard(e.key, e.value)),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPreoccupationBanner() => GestureDetector(
    onTap: _ouvrirPreoccupation,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange.withOpacity(0.08), _orange.withOpacity(0.04)],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orange.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _orange.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.assignment_outlined, color: _orange, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Une préoccupation sur ce devoir ?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _dark)),
            const SizedBox(height: 2),
            Text('Posez-la dans le forum pour obtenir une explication',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
          child: const Text('Demander', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    ),
  );

  Widget _buildReponseCard(int index, Map rep) {
    final correct = rep['correct'];
    final isOk = correct == true;
    final color = isOk ? Colors.green : (correct == false ? Colors.red : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isOk ? Icons.check_rounded : Icons.close_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Question ${index + 1}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          const Spacer(),
          if (rep['points'] != null)
            Text('+${rep['points']} pt', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        Text(rep['question'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dark, height: 1.4)),
        if (rep['votre_reponse'] != null) ...[
          const SizedBox(height: 8),
          _ligne('Votre réponse', rep['votre_reponse'], isOk ? Colors.green : Colors.red),
        ],
        if (!isOk && rep['bonne_reponse'] != null) ...[
          const SizedBox(height: 4),
          _ligne('Bonne réponse', rep['bonne_reponse'], Colors.green),
        ],
        if (rep['commentaire'] != null && rep['commentaire'].toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.comment_outlined, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(rep['commentaire'],
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _ligne(String label, String valeur, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label : ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      Expanded(child: Text(valeur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────
class _ForumStandalone extends StatelessWidget {
  final int? scrollToQuestionId;
  const _ForumStandalone({this.scrollToQuestionId});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(
      backgroundColor: const Color(0xFF161B22),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('Forum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      elevation: 0,
    ),
    body: ForumPage(scrollToQuestionId: scrollToQuestionId),
  );
}
