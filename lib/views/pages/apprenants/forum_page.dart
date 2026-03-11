import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/form_question_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────
const String _base = 'https://yekiapp.pythonanywhere.com/api';

const Color _teal   = Color(0xFF008088);
const Color _dark   = Color(0xFF0D1B2A);
const Color _bg     = Color(0xFFF4F9FB);
const Color _accent = Color(0xFFFF7F77);

// Couleurs par source
const Map<String, Color> _sourceColors = {
  "lecon":    Color(0xFF1565C0),  // Bleu
  "exercice": Color(0xFF6A1B9A),  // Violet
  "devoir":   Color(0xFFE65100),  // Orange
  "libre":    Color(0xFF2E7D32),  // Vert
};

const Map<String, IconData> _sourceIcons = {
  "lecon":    Icons.play_lesson_rounded,
  "exercice": Icons.edit_note_rounded,
  "devoir":   Icons.assignment_rounded,
  "libre":    Icons.chat_bubble_outline_rounded,
};

const Map<String, String> _sourceLabels = {
  "lecon":    "Leçon",
  "exercice": "Exercice",
  "devoir":   "Devoir",
  "libre":    "Libre",
};

// ─────────────────────────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────────────────────────
class QuestionForum {
  final int    id;
  final String contenu;
  final String source;
  final String creeLe;
  final bool   estResolue;
  final int    nbVues;
  final int    nbReponses;
  final String auteurNom;
  final String auteurUsername;

  // Contexte
  final int?   leconId;
  final String leconTitre;
  final int?   coursId;
  final String coursTitre;
  final int?   exerciceId;
  final String exerciceTitre;
  final int?   devoirId;
  final String devoirTitre;

  List<ReponseQuestion> reponses;

  QuestionForum({
    required this.id,
    required this.contenu,
    required this.source,
    required this.creeLe,
    required this.estResolue,
    required this.nbVues,
    required this.nbReponses,
    required this.auteurNom,
    required this.auteurUsername,
    this.leconId,
    this.leconTitre = '',
    this.coursId,
    this.coursTitre = '',
    this.exerciceId,
    this.exerciceTitre = '',
    this.devoirId,
    this.devoirTitre = '',
    this.reponses = const [],
  });

  factory QuestionForum.fromJson(Map<String, dynamic> j) => QuestionForum(
    id:             j['id'],
    contenu:        j['contenu'] ?? '',
    source:         j['source'] ?? 'libre',
    creeLe:         j['cree_le'] ?? '',
    estResolue:     j['est_resolue'] ?? false,
    nbVues:         j['nb_vues'] ?? 0,
    nbReponses:     j['nb_reponses'] ?? 0,
    auteurNom:      j['auteur_nom'] ?? '',
    auteurUsername: j['auteur_username'] ?? '',
    leconId:        j['lecon_id'],
    leconTitre:     j['lecon_titre'] ?? '',
    coursId:        j['cours_id'],
    coursTitre:     j['cours_titre'] ?? '',
    exerciceId:     j['exercice_id'],
    exerciceTitre:  j['exercice_titre'] ?? '',
    devoirId:       j['devoir_id'],
    devoirTitre:    j['devoir_titre'] ?? '',
    reponses:       (j['reponses'] as List? ?? [])
                        .map((r) => ReponseQuestion.fromJson(r)).toList(),
  );

  String get contexteLabel {
    switch (source) {
      case 'lecon':    return leconTitre.isNotEmpty ? leconTitre : 'Leçon';
      case 'exercice': return exerciceTitre.isNotEmpty ? exerciceTitre : 'Exercice';
      case 'devoir':   return devoirTitre.isNotEmpty ? devoirTitre : 'Devoir';
      default:         return 'Question libre';
    }
  }
}

class ReponseQuestion {
  final int    id;
  final String contenu;
  final String creeLe;
  final bool   estSolution;
  final String auteurNom;
  final String auteurUsername;
  final int    nbLikes;
  final bool   monLike;

  ReponseQuestion({
    required this.id,
    required this.contenu,
    required this.creeLe,
    required this.estSolution,
    required this.auteurNom,
    required this.auteurUsername,
    required this.nbLikes,
    required this.monLike,
  });

  factory ReponseQuestion.fromJson(Map<String, dynamic> j) => ReponseQuestion(
    id:             j['id'],
    contenu:        j['contenu'] ?? '',
    creeLe:         j['cree_le'] ?? '',
    estSolution:    j['est_solution'] ?? false,
    auteurNom:      j['auteur_nom'] ?? '',
    auteurUsername: j['auteur_username'] ?? '',
    nbLikes:        j['nb_likes'] ?? 0,
    monLike:        j['mon_like'] ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────
Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

String _timeAgo(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return timeago.format(dt, locale: 'fr');
  } catch (_) {
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────
// PAGE FORUM — LISTE DES QUESTIONS (temps réel par polling)
// ─────────────────────────────────────────────────────────────────
class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with TickerProviderStateMixin {
  bool                  _loading     = true;
  List<QuestionForum>   _questions   = [];
  String                _sourceFiltre = 'tous';
  bool?                 _filtreResolue;
  final TextEditingController _search = TextEditingController();
  String                _searchText  = '';

  Timer?                _pollTimer;
  late AnimationController _fabCtrl;

  // Stats
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _charger();
    _startPolling();
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _fabCtrl.dispose();
    _search.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Rafraîchir toutes les 5 secondes (polling léger)
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _charger(silent: true));
  }

  Future<void> _charger({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final token = await _getToken();

    final params = <String, String>{};
    if (_sourceFiltre != 'tous') params['source'] = _sourceFiltre;
    if (_filtreResolue != null) params['resolue'] = _filtreResolue! ? 'true' : 'false';

    try {
      // Charger questions
      final res = await http.get(
        Uri.parse('$_base/forum/questions/').replace(queryParameters: params),
        headers: _headers(token),
      );
      // Charger stats
      final statsRes = await http.get(
        Uri.parse('$_base/forum/stats/'),
        headers: _headers(token),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => QuestionForum.fromJson(j))
            .toList();
        setState(() {
          _questions = data;
          _loading   = false;
        });
      }
      if (statsRes.statusCode == 200) {
        setState(() => _stats = Map<String, int>.from(jsonDecode(statsRes.body)));
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  List<QuestionForum> get _filtered {
    if (_searchText.isEmpty) return _questions;
    final q = _searchText.toLowerCase();
    return _questions.where((x) =>
        x.contenu.toLowerCase().contains(q) ||
        x.auteurNom.toLowerCase().contains(q) ||
        x.contexteLabel.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildSourceFilters()),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: _teal,
                    onRefresh: _charger,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildQuestionCard(_filtered[i]),
                    ),
                  ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          backgroundColor: _teal,
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          label: const Text('Poser une question',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          onPressed: () => _ouvrirFormQuestion(context),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _dark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B2A), Color(0xFF008088)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Forum',
                      style: TextStyle(
                          color: Colors.white, fontSize: 30,
                          fontWeight: FontWeight.w900, height: 1)),
                  const SizedBox(height: 4),
                  Text('Questions de la communauté',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────
  Widget _buildStats() {
    if (_stats.isEmpty) return const SizedBox.shrink();
    return Container(
      color: _dark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        _statChip('${_stats['total'] ?? 0}', 'Questions', _teal),
        const SizedBox(width: 8),
        _statChip('${_stats['resolues'] ?? 0}', 'Résolues', Colors.green),
        const SizedBox(width: 8),
        _statChip('${_stats['lecons'] ?? 0}', 'Leçons', _sourceColors['lecon']!),
        const SizedBox(width: 8),
        _statChip('${_stats['devoirs'] ?? 0}', 'Devoirs', _sourceColors['devoir']!),
      ]),
    );
  }

  Widget _statChip(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 9)),
    ]),
  );

  // ── Barre de recherche ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          hintText: 'Rechercher une question...',
          prefixIcon: const Icon(Icons.search, color: _teal),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _searchText = '');
                  })
              : null,
          filled: true,
          fillColor: _bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Filtres source ─────────────────────────────────────────────
  Widget _buildSourceFilters() {
    final filtres = ['tous', 'lecon', 'exercice', 'devoir', 'libre'];
    final labels  = ['Tous', 'Leçons', 'Exercices', 'Devoirs', 'Libres'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(filtres.length, (i) {
            final f        = filtres[i];
            final selected = _sourceFiltre == f;
            final color    = f == 'tous' ? _teal : (_sourceColors[f] ?? _teal);
            return GestureDetector(
              onTap: () {
                setState(() => _sourceFiltre = f);
                _charger();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? color : Colors.grey.shade300),
                ),
                child: Row(children: [
                  if (f != 'tous') ...[
                    Icon(_sourceIcons[f], size: 13,
                        color: selected ? Colors.white : color),
                    const SizedBox(width: 5),
                  ],
                  Text(labels[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.grey.shade600)),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Carte question ─────────────────────────────────────────────
  Widget _buildQuestionCard(QuestionForum q) {
    final color = _sourceColors[q.source] ?? _teal;
    final icon  = _sourceIcons[q.source]  ?? Icons.chat_bubble_outline_rounded;
    final label = _sourceLabels[q.source] ?? 'Libre';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailQuestionPage(questionId: q.id)),
      ).then((_) => _charger()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // ── Bandeau source (couleur distincte) ───────────────
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 13, color: color),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: color, letterSpacing: 0.4)),
                const SizedBox(width: 6),
                if (q.contexteLabel.isNotEmpty && q.source != 'libre')
                  Expanded(
                    child: Text(
                      '— ${q.contexteLabel}',
                      style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                if (q.estResolue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded,
                          size: 11, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text('Résolue',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green.shade700,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),

            // ── Contenu ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.contenu,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: _dark, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        q.auteurNom.isNotEmpty ? q.auteurNom[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const Spacer(),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('${q.nbReponses}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Icon(Icons.visibility_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('${q.nbVues}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Text(_timeAgo(q.creeLe),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Aucune question trouvée',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
        const SizedBox(height: 8),
        TextButton(onPressed: _charger, child: const Text('Actualiser')),
      ],
    ),
  );

  // ── Formulaire nouvelle question libre ─────────────────────────
  void _ouvrirFormQuestion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormQuestionSheet(
        source: 'libre',
        onSoumis: _charger,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PAGE DÉTAIL QUESTION — avec réponses temps réel
// ─────────────────────────────────────────────────────────────────
class DetailQuestionPage extends StatefulWidget {
  final int questionId;
  const DetailQuestionPage({super.key, required this.questionId});

  @override
  State<DetailQuestionPage> createState() => _DetailQuestionPageState();
}

class _DetailQuestionPageState extends State<DetailQuestionPage> {
  bool              _loading  = true;
  QuestionForum?    _question;
  Timer?            _pollTimer;
  final TextEditingController _ctrl = TextEditingController();
  bool              _sending  = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _charger();
    // Polling toutes les 3 secondes pour les réponses
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _charger(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _charger({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/forum/questions/${widget.questionId}/'),
        headers: _headers(token),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final prevCount = _question?.reponses.length ?? 0;
        final q = QuestionForum.fromJson(jsonDecode(res.body));
        setState(() {
          _question = q;
          _loading  = false;
        });
        // Auto-scroll si nouvelle réponse
        if (!silent && q.reponses.length > prevCount && _scroll.hasClients) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _ctrl.text.trim();
    if (texte.isEmpty) return;
    setState(() => _sending = true);
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('$_base/forum/questions/${widget.questionId}/repondre/'),
        headers: _headers(token),
        body: jsonEncode({'contenu': texte}),
      );
      if (res.statusCode == 201) {
        _ctrl.clear();
        FocusScope.of(context).unfocus();
        await _charger();
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _liker(int reponseId) async {
    final token = await _getToken();
    await http.post(
      Uri.parse('$_base/forum/reponses/$reponseId/liker/'),
      headers: _headers(token),
    );
    _charger(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _teal)));
    }
    if (q == null) {
      return const Scaffold(body: Center(child: Text('Question introuvable')));
    }

    final color = _sourceColors[q.source] ?? _teal;
    final icon  = _sourceIcons[q.source]  ?? Icons.chat_bubble_outline_rounded;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(_sourceLabels[q.source] ?? 'Forum',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          if (q.estResolue)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade400),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Question principale ────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                // Carte question
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border(left: BorderSide(color: color, width: 5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contexte source
                      if (q.source != 'libre' && q.contexteLabel.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 6),
                            Text(q.contexteLabel,
                                style: TextStyle(
                                    fontSize: 11, color: color,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),

                      Text(q.contenu,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: _dark, height: 1.5)),

                      const SizedBox(height: 12),
                      Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            q.auteurNom.isNotEmpty ? q.auteurNom[0].toUpperCase() : '?',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(q.auteurNom.isNotEmpty ? q.auteurNom : q.auteurUsername,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const Spacer(),
                        Text(_timeAgo(q.creeLe),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Titre réponses
                Row(children: [
                  Text('${q.reponses.length} réponse${q.reponses.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: _dark)),
                  const Spacer(),
                  // Indicateur temps réel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('En direct',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green.shade700,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),

                const SizedBox(height: 12),

                // Liste réponses
                ...q.reponses.map((r) => _buildReponseTile(r)),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Zone de saisie ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Écrire une réponse...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sending ? null : _envoyer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _sending ? Colors.grey.shade300 : _teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _teal.withOpacity(0.4), blurRadius: 10),
                    ],
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReponseTile(ReponseQuestion r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: r.estSolution ? const Color(0xFFF0FFF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: r.estSolution ? Colors.green.shade200 : Colors.grey.shade100,
          width: r.estSolution ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.estSolution)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, size: 13, color: Colors.green.shade700),
                const SizedBox(width: 5),
                Text('Solution acceptée',
                    style: TextStyle(
                        fontSize: 11, color: Colors.green.shade800,
                        fontWeight: FontWeight.w700)),
              ]),
            ),

          Text(r.contenu,
              style: const TextStyle(fontSize: 14, height: 1.5, color: _dark)),

          const SizedBox(height: 10),
          Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: _teal.withOpacity(0.15),
              child: Text(
                r.auteurNom.isNotEmpty ? r.auteurNom[0].toUpperCase() : '?',
                style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(width: 7),
            Text(r.auteurNom.isNotEmpty ? r.auteurNom : r.auteurUsername,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Spacer(),
            Text(_timeAgo(r.creeLe),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _liker(r.id),
              child: Row(children: [
                Icon(
                  r.monLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 16,
                  color: r.monLike ? Colors.redAccent : Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text('${r.nbLikes}',
                    style: TextStyle(
                        fontSize: 12,
                        color: r.monLike ? Colors.redAccent : Colors.grey.shade500)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

