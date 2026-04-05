import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _borderMedium = Color(0xFFD0D4D8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);

class _ExerciceItem {
  final int    id, etoiles, dureeMinutes, tentativesMax;
  final String titre, enonce;
  final int    nbQuestions;

  const _ExerciceItem({
    required this.id, required this.titre, required this.enonce,
    required this.etoiles, required this.dureeMinutes,
    required this.tentativesMax, required this.nbQuestions,
  });

  factory _ExerciceItem.fromJson(Map<String, dynamic> j) => _ExerciceItem(
    id:            j['id'] as int,
    titre:         j['titre'] as String,
    enonce:        j['enonce'] as String,
    etoiles:       j['etoiles'] as int,
    dureeMinutes:  j['duree_minutes'] ?? 10,
    tentativesMax: j['tentatives_max'] ?? 1,
    nbQuestions:   (j['questions'] as List?)?.length ?? 0,
  );
}

class _QuestionItem {
  final int    id, points;
  final String text, typeQuestion, bonneReponse;
  final List<String> choix;

  const _QuestionItem({
    required this.id, required this.text, required this.typeQuestion,
    required this.bonneReponse, required this.points, required this.choix,
  });

  factory _QuestionItem.fromJson(Map<String, dynamic> j) => _QuestionItem(
    id:           j['id'] as int,
    text:         j['text'] as String,
    typeQuestion: j['type'] as String,
    bonneReponse: j['bonne_reponse'] ?? '',
    points:       j['points'] as int,
    choix:        (j['choix'] as List?)?.map((c) => c['texte'] as String).toList() ?? [],
  );
}

class ExercicesCoursPage extends StatefulWidget {
  final String          coursId;
  final String          coursTitre;
  final RoleEnseignant? role;
  final void Function(int questionId)? onNaviguerForum;
  final Color courseColor;

  const ExercicesCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    this.onNaviguerForum,
    required this.courseColor,
  });

  @override
  State<ExercicesCoursPage> createState() => _ExercicesCoursPageState();
}

class _ExercicesCoursPageState extends State<ExercicesCoursPage> {
  static const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

  List<_ExerciceItem> _exercices    = [];
  List<_ExerciceItem> _filtered     = [];
  bool                _loading      = true;
  int                 _etoileFilter = 0;
  final _searchCtrl = TextEditingController();

  bool get _canEdit =>
      widget.role == RoleEnseignant.enseignantPrincipal ||
      widget.role == RoleEnseignant.enseignantCadre;

  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<Map<String, String>> _authHeaders() async {
    final t = await _getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Token $t'};
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final h   = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/cours/${widget.coursId}/exercices/'),
        headers: h,
      );
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        setState(() {
          _exercices = list.map(_ExerciceItem.fromJson).toList();
          _applyFilter();
        });
      }
    } catch (e) {
      _snack('Erreur réseau : $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _exercices.where((e) {
        final matchEtoile = _etoileFilter == 0 || e.etoiles == _etoileFilter;
        final matchSearch = q.isEmpty ||
            e.titre.toLowerCase().contains(q) ||
            e.enonce.toLowerCase().contains(q);
        return matchEtoile && matchSearch;
      }).toList();
    });
  }

  Future<void> _createExercice({
    required String titre, required String enonce,
    required int etoiles, required int duree, required int tentatives,
  }) async {
    final h = await _authHeaders();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cours/${widget.coursId}/exercices/ajouter/'),
        headers: h,
        body: jsonEncode({
          'titre': titre, 'enonce': enonce, 'etoiles': etoiles,
          'duree_minutes': duree, 'tentatives_max': tentatives,
        }),
      );
      if (res.statusCode == 201) {
        _snack('Exercice créé !');
        await _fetch();
      } else {
        final err = jsonDecode(res.body);
        _snack(err['detail'] ?? err.toString(), error: true);
      }
    } catch (e) { _snack('Erreur : $e', error: true); }
  }

  Future<List<_QuestionItem>> _fetchQuestions(int exerciceId) async {
    try {
      final h   = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/exercices/$exerciceId/questions/'),
        headers: h,
      );
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        return list.map(_QuestionItem.fromJson).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> _createQuestion({
    required int    exerciceId,
    required String text,
    required String typeQuestion,
    required String bonneReponse,
    required int    points,
    required List<Map<String, String>> choix,
  }) async {
    final h = await _authHeaders();
    try {
      final body = <String, dynamic>{
        'text': text, 'type_question': typeQuestion,
        'bonne_reponse': bonneReponse, 'points': points,
      };
      if (typeQuestion == 'qcm') body['choix'] = choix;
      final res = await http.post(
        Uri.parse('$_baseUrl/exercices/$exerciceId/questions/ajouter/'),
        headers: h, body: jsonEncode(body),
      );
      return res.statusCode == 201;
    } catch (_) { return false; }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _white)),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? Center(child: CircularProgressIndicator(color: widget.courseColor))
            : RefreshIndicator(
                onRefresh: _fetch,
                color: widget.courseColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Exercices',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
                            Text(widget.coursTitre,
                                style: TextStyle(fontSize: 12, color: _textLight),
                                overflow: TextOverflow.ellipsis),
                          ]),
                          IconButton(
                            icon: Icon(Icons.refresh, color: widget.courseColor),
                            onPressed: _fetch,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderLight, width: 1.5),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un exercice…',
                            hintStyle: TextStyle(color: _textLight, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: widget.courseColor, size: 20),
                            filled: true,
                            fillColor: _white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _filterChip(0, 'Tous'),
                          ...List.generate(5, (i) => _filterChip(i + 1,
                              ['Très facile', 'Facile', 'Moyen', 'Difficile', 'Expert'][i])),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      if (_filtered.isEmpty) _buildEmpty()
                      else ..._filtered.map((ex) => _buildCard(ex)),
                    ],
                  ),
                ),
              ),
        if (_canEdit)
          Positioned(
            right: 20, bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _showCreateExerciceSheet,
              backgroundColor: widget.courseColor,
              icon: const Icon(Icons.add, color: _white, size: 18),
              label: const Text('Ajouter',
                  style: TextStyle(color: _white, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _filterChip(int val, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(val == 0 ? label : '${'★' * val} $label',
          style: TextStyle(fontSize: 12,
              color: _etoileFilter == val ? _white : _textMedium)),
      selected:        _etoileFilter == val,
      onSelected:      (_) => setState(() { _etoileFilter = val; _applyFilter(); }),
      selectedColor:   widget.courseColor,
      backgroundColor: _white,
      side:            BorderSide(color: _borderLight, width: 1),
      showCheckmark:   false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _buildCard(_ExerciceItem ex) {
    final colors = [widget.courseColor, Colors.indigo, Colors.orange, Colors.purple, Colors.blue];
    final col    = colors[ex.id % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: col.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: col.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: col.withOpacity(0.2), width: 0.8),
              ),
              child: Icon(Icons.assignment_outlined, color: col, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex.titre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: List.generate(5, (i) => Icon(
                i < ex.etoiles ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 14,
              ))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: col.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: col.withOpacity(0.2), width: 0.5),
              ),
              child: Text('${ex.nbQuestions} Q',
                  style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(ex.enonce,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: _textMedium)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            _infoPill(Icons.timer_outlined, '${ex.dureeMinutes} min', Colors.blue),
            const SizedBox(width: 8),
            _infoPill(Icons.repeat_outlined,
                '${ex.tentativesMax} essai${ex.tentativesMax > 1 ? "s" : ""}', Colors.orange),
            const Spacer(),
            if (_canEdit)
              _actionButton(
                icon:  Icons.quiz_outlined,
                label: 'Questions',
                color: Colors.deepPurple,
                onTap: () => _openQuestionsSheet(ex),
              )
            else
              _actionButton(
                icon:  Icons.play_arrow_rounded,
                label: 'Traiter',
                color: widget.courseColor,
                onTap: () => _ouvrirExercice(ex),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoPill(IconData icon, String label, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: col.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: col.withOpacity(0.15), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: col), const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _actionButton({
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.quiz_outlined, size: 64, color: _borderMedium),
        const SizedBox(height: 16),
        Text('Aucun exercice',
            style: TextStyle(fontSize: 18, color: _textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          _canEdit
              ? 'Appuyez sur + pour créer le premier exercice.'
              : 'Aucun exercice disponible pour ce cours.',
          style: TextStyle(fontSize: 13, color: _textLight),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );

  void _ouvrirExercice(_ExerciceItem ex) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PasserExercicePage(
        exerciceId:      ex.id,
        coursId:         int.tryParse(widget.coursId),
        coursTitre:      widget.coursTitre,
      ),
    )).then((_) => _fetch());
  }

  void _showCreateExerciceSheet() {
    final titreCtrl  = TextEditingController();
    final enonceCtrl = TextEditingController();
    int  etoiles    = 1;
    int  duree      = 10;
    int  tentatives = 1;
    bool loading    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              _sheetTitle(Icons.assignment_add, 'Nouvel exercice', widget.courseColor),
              const SizedBox(height: 24),
              _fieldLabel('Titre'),
              const SizedBox(height: 6),
              _textField(titreCtrl, 'Ex : Dérivées et primitives'),
              const SizedBox(height: 16),
              _fieldLabel('Énoncé / Description'),
              const SizedBox(height: 6),
              _textField(enonceCtrl, 'Décrivez l\'objectif de l\'exercice…', maxLines: 3),
              const SizedBox(height: 20),
              _fieldLabel('Difficulté'),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => GestureDetector(
                onTap: () => ss(() => etoiles = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(i < etoiles ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                ),
              ))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('Durée (min)'),
                  const SizedBox(height: 6),
                  _counter(duree, 1, 180, (v) => ss(() => duree = v), widget.courseColor),
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _fieldLabel('Tentatives max'),
                  const SizedBox(height: 6),
                  _counter(tentatives, 1, 10, (v) => ss(() => tentatives = v), Colors.orange),
                ])),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.courseColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: loading ? null : () async {
                    if (titreCtrl.text.trim().isEmpty) { _snack('Le titre est requis.', error: true); return; }
                    if (enonceCtrl.text.trim().isEmpty) { _snack('L\'énoncé est requis.', error: true); return; }
                    ss(() => loading = true);
                    await _createExercice(
                      titre: titreCtrl.text.trim(), enonce: enonceCtrl.text.trim(),
                      etoiles: etoiles, duree: duree, tentatives: tentatives,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                      : const Text('Créer l\'exercice',
                          style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _openQuestionsSheet(_ExerciceItem ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionsSheet(
        exercice:       ex,
        canEdit:        _canEdit,
        fetchQuestions: _fetchQuestions,
        createQuestion: _createQuestion,
        courseColor:    widget.courseColor,
      ),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(width: 40, height: 4,
        decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(10))),
  );

  Widget _sheetTitle(IconData icon, String title, Color col) => Row(children: [
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: col, size: 22),
    ),
    const SizedBox(width: 14),
    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _textDark)),
  ]);

  Widget _fieldLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMedium));

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1}) => TextField(
    controller: ctrl, maxLines: maxLines, style: const TextStyle(fontSize: 14, color: _textDark),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: _textLight, fontSize: 13),
      filled: true, fillColor: _bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: widget.courseColor, width: 1.5),
      ),
    ),
  );

  Widget _counter(int value, int min, int max, void Function(int) onChange, Color col) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _counterBtn(Icons.remove, col, value > min ? () => onChange(value - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark))),
        _counterBtn(Icons.add, col, value < max ? () => onChange(value + 1) : null),
      ]);

  Widget _counterBtn(IconData icon, Color col, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(
          color: onTap != null ? col.withOpacity(0.1) : _borderLight,
          borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: onTap != null ? col : _textLight)),
  );
}

// ══════════════════════════════════════════════════════════════════
//  _QuestionsSheet
// ══════════════════════════════════════════════════════════════════
class _QuestionsSheet extends StatefulWidget {
  final _ExerciceItem exercice;
  final bool          canEdit;
  final Future<List<_QuestionItem>> Function(int) fetchQuestions;
  final Future<bool> Function({
    required int    exerciceId,
    required String text,
    required String typeQuestion,
    required String bonneReponse,
    required int    points,
    required List<Map<String, String>> choix,
  }) createQuestion;
  final Color courseColor;

  const _QuestionsSheet({
    required this.exercice, required this.canEdit,
    required this.fetchQuestions, required this.createQuestion,
    required this.courseColor,
  });

  @override
  State<_QuestionsSheet> createState() => _QuestionsSheetState();
}

class _QuestionsSheetState extends State<_QuestionsSheet> {
  List<_QuestionItem> _questions = [];
  bool _loadingQ  = true;
  bool _showForm  = false;

  final _texteCtrl = TextEditingController();
  String _type     = 'qcm';
  int    _points   = 1;

  final List<TextEditingController> _choixCtrl = [
    TextEditingController(), TextEditingController(),
  ];
  int _correctIndex = 0;

  final _bonneRepCtrl = TextEditingController();
  bool _submitting    = false;

  @override
  void initState() { super.initState(); _loadQuestions(); }

  @override
  void dispose() {
    _texteCtrl.dispose(); _bonneRepCtrl.dispose();
    for (final c in _choixCtrl) c.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loadingQ = true);
    final qs = await widget.fetchQuestions(widget.exercice.id);
    setState(() { _questions = qs; _loadingQ = false; });
  }

  void _resetForm() {
    _texteCtrl.clear(); _bonneRepCtrl.clear();
    for (final c in _choixCtrl) c.clear();
    while (_choixCtrl.length > 2) _choixCtrl.removeLast();
    setState(() { _type = 'qcm'; _points = 1; _correctIndex = 0; _showForm = false; });
  }

  Future<void> _submit() async {
    final texte = _texteCtrl.text.trim();
    if (texte.isEmpty) { _snack('L\'énoncé est requis.', error: true); return; }
    String bonneReponse; List<Map<String, String>> choix = [];
    if (_type == 'qcm') {
      if (_choixCtrl.any((c) => c.text.trim().isEmpty)) { _snack('Remplissez tous les choix.', error: true); return; }
      if (_correctIndex >= _choixCtrl.length) { _snack('Sélectionnez la bonne réponse.', error: true); return; }
      bonneReponse = _choixCtrl[_correctIndex].text.trim();
      choix = _choixCtrl.map((c) => {'texte': c.text.trim()}).toList();
    } else {
      bonneReponse = _bonneRepCtrl.text.trim();
      if (bonneReponse.isEmpty) { _snack('Indiquez la bonne réponse.', error: true); return; }
    }
    setState(() => _submitting = true);
    final ok = await widget.createQuestion(
      exerciceId: widget.exercice.id, text: texte, typeQuestion: _type,
      bonneReponse: bonneReponse, points: _points, choix: choix,
    );
    setState(() => _submitting = false);
    if (ok) { _snack('Question ajoutée !'); _resetForm(); _loadQuestions(); }
    else    { _snack('Erreur lors de l\'envoi.', error: true); }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _white)),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.93),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        _buildHeader(),
        Divider(color: _borderLight, height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Column(children: [
              if (_showForm) _buildForm(),
              if (_loadingQ)
                const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
              else if (_questions.isEmpty && !_showForm)
                _buildEmptyState()
              else
                ..._questions.asMap().entries.map((e) => _buildQuestionCard(e.key + 1, e.value)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
    child: Column(children: [
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: _borderLight, borderRadius: BorderRadius.circular(10)))),
      const SizedBox(height: 14),
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.quiz_outlined, color: Colors.deepPurple, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.exercice.titre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              overflow: TextOverflow.ellipsis),
          Text('${_questions.length} question${_questions.length != 1 ? "s" : ""}',
              style: TextStyle(fontSize: 12, color: _textLight)),
        ])),
        if (widget.canEdit && !_showForm)
          ElevatedButton.icon(
            onPressed: () => setState(() => _showForm = true),
            icon: const Icon(Icons.add, size: 16, color: _white),
            label: const Text('Ajouter',
                style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
          ),
      ]),
    ]),
  );

  Widget _buildForm() => Container(
    margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.deepPurple.withOpacity(0.03),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.deepPurple.withOpacity(0.15), width: 1),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Nouvelle question',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        IconButton(onPressed: _resetForm, icon: const Icon(Icons.close),
            color: _textLight, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      const SizedBox(height: 18),
      _sectionLabel('Type de question'), const SizedBox(height: 8),
      Row(children: [
        _typeBtn('qcm',   'QCM',         Icons.check_box_outlined),
        const SizedBox(width: 10),
        _typeBtn('texte', 'Texte libre', Icons.text_fields),
      ]),
      const SizedBox(height: 18),
      _sectionLabel('Énoncé de la question'), const SizedBox(height: 8),
      TextField(controller: _texteCtrl, maxLines: 4, style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: _inputDeco('Écrivez la question ici…')),
      const SizedBox(height: 18),
      Row(children: [_sectionLabel('Points :'), const SizedBox(width: 12), _smallCounter()]),
      const SizedBox(height: 18),
      if (_type == 'qcm') ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _sectionLabel('Choix de réponses'),
          if (_choixCtrl.length < 6) TextButton.icon(
            onPressed: () => setState(() => _choixCtrl.add(TextEditingController())),
            icon: const Icon(Icons.add, size: 15, color: Colors.deepPurple),
            label: const Text('Ajouter un choix',
                style: TextStyle(color: Colors.deepPurple, fontSize: 12)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Cochez (●) le choix correct', style: TextStyle(fontSize: 11, color: _textLight)),
        const SizedBox(height: 10),
        ...List.generate(_choixCtrl.length, (i) => _buildChoixRow(i)),
        if (_choixCtrl.length > 2) ...[
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _choixCtrl.last.dispose(); _choixCtrl.removeLast();
                if (_correctIndex >= _choixCtrl.length) _correctIndex = _choixCtrl.length - 1;
              }),
              icon: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.red),
              label: const Text('Supprimer le dernier', style: TextStyle(color: Colors.red, fontSize: 12)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ),
        ],
      ],
      if (_type == 'texte') ...[
        _sectionLabel('Réponse attendue (correction auto)'), const SizedBox(height: 8),
        TextField(controller: _bonneRepCtrl, style: const TextStyle(fontSize: 14, color: _textDark),
            decoration: _inputDeco('Tapez la bonne réponse exacte…')),
        const SizedBox(height: 6),
        Text('La réponse de l\'apprenant sera comparée à ce texte (insensible à la casse).',
            style: TextStyle(fontSize: 11, color: _textLight)),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
              : const Text('Publier la question',
                  style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    ]),
  );

  Widget _buildChoixRow(int i) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => setState(() => _correctIndex = i),
        child: Container(width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _correctIndex == i ? Colors.deepPurple : _white,
            border: Border.all(
                color: _correctIndex == i ? Colors.deepPurple : _borderMedium, width: 2),
          ),
          child: _correctIndex == i ? const Icon(Icons.check, color: _white, size: 14) : null),
      ),
      const SizedBox(width: 12),
      Expanded(child: TextField(controller: _choixCtrl[i], style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: _inputDeco('Choix ${i + 1}').copyWith(isDense: true))),
    ]),
  );

  Widget _buildQuestionCard(int num, _QuestionItem q) {
    final isQcm = q.typeQuestion == 'qcm';
    return Container(
      margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Q$num', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: isQcm ? Colors.blue.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6)),
            child: Text(isQcm ? 'QCM' : 'Texte libre',
                style: TextStyle(color: isQcm ? Colors.blue : Colors.orange, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.stars_outlined, size: 14, color: Colors.amber), const SizedBox(width: 4),
            Text('${q.points} pt${q.points > 1 ? "s" : ""}',
                style: TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 12),
        Text(q.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 12),
        if (isQcm && q.choix.isNotEmpty) ...q.choix.map((c) {
          final correct = c == q.bonneReponse;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: correct ? Colors.green.withOpacity(0.08) : _bgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: correct ? Colors.green.shade300 : _borderLight, width: 1),
            ),
            child: Row(children: [
              Icon(correct ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16, color: correct ? Colors.green : _textLight),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: TextStyle(fontSize: 13,
                  color: correct ? Colors.green.shade700 : _textMedium,
                  fontWeight: correct ? FontWeight.w600 : FontWeight.normal))),
            ]),
          );
        }),
        if (!isQcm && q.bonneReponse.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 16), const SizedBox(width: 10),
              Text('Réponse : ${q.bonneReponse}',
                  style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildEmptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      Icon(Icons.quiz_outlined, size: 56, color: _borderMedium),
      const SizedBox(height: 16),
      Text('Aucune question pour l\'instant.',
          style: TextStyle(color: _textLight, fontWeight: FontWeight.w500)),
      if (widget.canEdit) ...[
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showForm = true),
          icon: const Icon(Icons.add, color: _white, size: 16),
          label: const Text('Créer la première question', style: TextStyle(color: _white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
        ),
      ],
    ]),
  );

  Widget _typeBtn(String val, String label, IconData icon) {
    final sel = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? Colors.deepPurple : _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? Colors.deepPurple : _borderLight, width: 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: sel ? _white : _textMedium),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: sel ? _white : _textMedium)),
          ]),
        ),
      ),
    );
  }

  Widget _smallCounter() => Row(mainAxisSize: MainAxisSize.min, children: [
    _cBtn(Icons.remove, _points > 1  ? () => setState(() => _points--) : null),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('$_points pt', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark))),
    _cBtn(Icons.add,    _points < 10 ? () => setState(() => _points++) : null),
  ]);

  Widget _cBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 30, height: 30,
      decoration: BoxDecoration(
          color: onTap != null ? Colors.deepPurple.withOpacity(0.08) : _borderLight,
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: onTap != null ? Colors.deepPurple : _textLight)),
  );

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMedium));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: _textLight, fontSize: 13),
    filled: true, fillColor: _white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _borderLight, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
    ),
  );
}