import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/form_question_sheet.dart';
import 'resultat_devoir_page.dart';

// ─────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────
const String _base   = 'https://yeki.pythonanywhere.com/api';
//const Color _primary = Color(0xFF2884A0);
const Color _teal    = Color(0xFF008088);
const Color _dark    = Color(0xFF0D1B2A);
const Color _bg      = Color(0xFFF4F9FB);
const Color _accent  = Color(0xFFFF7F77);
const Color _orange  = Color(0xFFE65100);

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ─────────────────────────────────────────────────────────────────
// MODÈLE DEVOIR COURS
// ─────────────────────────────────────────────────────────────────
class DevoirCours {
  final int     id;
  final String  titre;
  final String  description;
  final String  dateDebut;
  final String  dateLimite;
  final bool    estOuvert;
  final bool    estExpire;
  final String? statut;        // statut de la soumission de l'utilisateur
  final double? note;
  final double  noteSur;
  final int     nbQuestions;

  DevoirCours({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDebut,
    required this.dateLimite,
    required this.estOuvert,
    required this.estExpire,
    this.statut,
    this.note,
    this.noteSur = 20,
    this.nbQuestions = 0,
  });

  factory DevoirCours.fromJson(Map<String, dynamic> j) => DevoirCours(
    id:          j['id'],
    titre:       j['titre'] ?? '',
    description: j['description'] ?? '',
    dateDebut:   j['date_debut'] ?? '',
    dateLimite:  j['date_limite'] ?? '',
    estOuvert:   j['est_ouvert'] ?? false,
    estExpire:   j['est_expire'] ?? false,
    statut:      j['ma_soumission']?['statut'],
    note:        j['ma_soumission']?['note'] != null
                     ? (j['ma_soumission']['note'] as num).toDouble() : null,
    noteSur:     (j['note_sur'] as num? ?? 20).toDouble(),
    nbQuestions: j['nb_questions'] ?? 0,
  );

  bool get aSoumis => statut != null;
  bool get estCorrige => statut == 'corrige';
  bool get peutPoserQuestion => aSoumis || estExpire;
}

// ─────────────────────────────────────────────────────────────────
// PAGE DEVOIRS D'UN COURS PRÉCIS
// ─────────────────────────────────────────────────────────────────
class DevoirsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;

  const DevoirsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
  });

  @override
  State<DevoirsCoursPage> createState() => _DevoirsCoursPageState();
}

class _DevoirsCoursPageState extends State<DevoirsCoursPage>
    with SingleTickerProviderStateMixin {
  bool               _loading   = true;
  List<DevoirCours>  _devoirs   = [];
  String             _filtreStatut = 'tous'; // tous | ouverts | soumis | expires

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      final labels = ['tous', 'ouverts', 'soumis', 'expires'];
      setState(() => _filtreStatut = labels[_tabCtrl.index]);
    });
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/cours/${widget.coursId}/devoirs/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => DevoirCours.fromJson(j))
            .toList();
        setState(() {
          _devoirs = data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<DevoirCours> get _filtres {
    switch (_filtreStatut) {
      case 'ouverts':  return _devoirs.where((d) => d.estOuvert && !d.aSoumis).toList();
      case 'soumis':   return _devoirs.where((d) => d.aSoumis).toList();
      case 'expires':  return _devoirs.where((d) => d.estExpire && !d.aSoumis).toList();
      default:         return _devoirs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: _dark,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1B2A), Color(0xFF008088)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          const Icon(Icons.assignment_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(widget.coursTitre,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12)),
                        ]),
                        const SizedBox(height: 6),
                        const Text('Devoirs',
                            style: TextStyle(
                                color: Colors.white, fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${_devoirs.length} devoir${_devoirs.length > 1 ? 's' : ''}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              indicatorColor: _accent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Ouverts'),
                Tab(text: 'Soumis'),
                Tab(text: 'Expirés'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : RefreshIndicator(
                color: _teal,
                onRefresh: _charger,
                child: _filtres.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                        itemCount: _filtres.length,
                        itemBuilder: (_, i) => _buildDevoirCard(_filtres[i]),
                      ),
              ),
      ),
    );
  }

  Widget _buildDevoirCard(DevoirCours d) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (d.estCorrige) {
      statusColor = Colors.green;
      statusLabel = 'Corrigé';
      statusIcon  = Icons.check_circle_rounded;
    } else if (d.aSoumis) {
      statusColor = Colors.orange;
      statusLabel = 'En attente';
      statusIcon  = Icons.hourglass_top_rounded;
    } else if (d.estOuvert) {
      statusColor = _teal;
      statusLabel = 'Ouvert';
      statusIcon  = Icons.lock_open_rounded;
    } else if (d.estExpire) {
      statusColor = Colors.red.shade400;
      statusLabel = 'Expiré';
      statusIcon  = Icons.lock_rounded;
    } else {
      statusColor = Colors.grey;
      statusLabel = 'À venir';
      statusIcon  = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── En-tête ──────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(statusIcon, color: statusColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(d.titre,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11, color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ]),

          const SizedBox(height: 10),

          // ── Description ──────────────────────────────────
          if (d.description.isNotEmpty)
            Text(d.description,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),

          const SizedBox(height: 12),

          // ── Meta infos ───────────────────────────────────
          Wrap(spacing: 12, runSpacing: 6, children: [
            _metaChip(Icons.quiz_outlined, '${d.nbQuestions} questions'),
            _metaChip(Icons.event_available_outlined,
                _formatDate(d.dateDebut)),
            _metaChip(Icons.event_busy_outlined,
                'Limite : ${_formatDate(d.dateLimite)}'),
            if (d.estCorrige && d.note != null)
              _metaChip(Icons.grade_rounded,
                  '${d.note!.toStringAsFixed(1)} / ${d.noteSur.toStringAsFixed(0)}',
                  color: Colors.green),
          ]),

          const SizedBox(height: 14),

          // ── Boutons action ───────────────────────────────
          Row(children: [
            // CTA principal
            if (d.estOuvert && !d.aSoumis)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _ouvrirDevoir(d),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else if (d.aSoumis)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _voirResultat(d),
                  icon: Icon(Icons.bar_chart_rounded, size: 16,
                      color: statusColor),
                  label: Text('Voir résultat',
                      style: TextStyle(color: statusColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: statusColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else if (d.estExpire)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: Colors.red),
                      SizedBox(width: 6),
                      Text('Délai expiré',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),

            // Bouton "Poser une question" visible si soumis ou expiré
            if (d.peutPoserQuestion) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _ouvrirQuestionForum(d),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _orange.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: _orange, size: 20),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color ?? Colors.grey.shade400),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey.shade500)),
    ],
  );

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  void _ouvrirDevoir(DevoirCours d) {
    // Navigation vers TraiterDevoirPage (existante)
    Navigator.pushNamed(
      context,
      '/traiter-devoir',
      arguments: {'devoirId': d.id, 'titre': d.titre},
    ).then((_) => _charger());
  }

  void _voirResultat(DevoirCours d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatDevoirPage(
          devoirId:   d.id,
          titre:      d.titre,
          coursId:    int.tryParse(widget.coursId),
          coursTitre: widget.coursTitre,
        ),
      ),
    );
  }

  void _ouvrirQuestionForum(DevoirCours d) {
    ouvrirQuestionForum(
      context,
      source:      'devoir',
      devoirId:    d.id,
      devoirTitre: d.titre,
      coursId:     int.tryParse(widget.coursId),
      coursTitre:  widget.coursTitre,
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          _filtreStatut == 'tous'
              ? 'Aucun devoir pour ce cours'
              : 'Aucun devoir dans cette catégorie',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _charger, child: const Text('Actualiser')),
      ],
    ),
  );
}
