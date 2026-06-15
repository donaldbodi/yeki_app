// lib/views/pages/apprenants/exercices_cours.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI EXERCICES — Design Unifié Premium (CORRIGÉ)
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/passer_exercice.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class _ExerciceItem {
  final int id;
  final int etoiles;
  final int dureeMinutes;
  final int tentativesMax;
  final String titre;
  final String enonce;
  final int nbQuestions;

  const _ExerciceItem({
    required this.id,
    required this.titre,
    required this.enonce,
    required this.etoiles,
    required this.dureeMinutes,
    required this.tentativesMax,
    required this.nbQuestions,
  });

  factory _ExerciceItem.fromJson(Map<String, dynamic> j) {
    return _ExerciceItem(
      id: j['id'] as int,
      titre: j['titre'] as String,
      enonce: j['enonce'] as String,
      etoiles: j['etoiles'] as int,
      dureeMinutes: j['duree_minutes'] ?? 10,
      tentativesMax: j['tentatives_max'] ?? 1,
      nbQuestions: (j['questions'] as List?)?.length ?? 0,
    );
  }
}

class _QuestionItem {
  final int id;
  final int points;
  final String text;
  final String typeQuestion;
  final String bonneReponse;
  final List<String> choix;

  const _QuestionItem({
    required this.id,
    required this.text,
    required this.typeQuestion,
    required this.bonneReponse,
    required this.points,
    required this.choix,
  });

  factory _QuestionItem.fromJson(Map<String, dynamic> j) {
    return _QuestionItem(
      id: j['id'] as int,
      text: j['text'] as String,
      typeQuestion: j['type'] as String,
      bonneReponse: j['bonne_reponse'] ?? '',
      points: j['points'] as int,
      choix: (j['choix'] as List?)?.map((c) => c['texte'] as String).toList() ?? [],
    );
  }
}

class ExercicesCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
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

class _ExercicesCoursPageState extends State<ExercicesCoursPage>
    with SingleTickerProviderStateMixin {
  List<_ExerciceItem> _exercices = [];
  List<_ExerciceItem> _filtered = [];
  bool _loading = true;
  int _etoileFilter = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  bool get _canEdit =>
      widget.role == RoleEnseignant.enseignantPrincipal ||
      widget.role == RoleEnseignant.enseignantCadre;

  Future<String?> _getToken() async {
    return (await SharedPreferences.getInstance()).getString('token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.value = 1.0;
    _searchCtrl.addListener(_applyFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cours/${widget.coursId}/exercices/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _exercices = list.map(_ExerciceItem.fromJson).toList();
          _applyFilter();
          _loading = false;
        });
        _animCtrl.forward(from: 0.0);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      _snack('Erreur réseau', error: true);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _exercices.where((exercice) {
        final matchEtoile = _etoileFilter == 0 || exercice.etoiles == _etoileFilter;
        final matchSearch = query.isEmpty ||
            exercice.titre.toLowerCase().contains(query) ||
            exercice.enonce.toLowerCase().contains(query);
        return matchEtoile && matchSearch;
      }).toList();
    });
  }

  Future<void> _createExercice({
    required String titre,
    required String enonce,
    required int etoiles,
    required int duree,
    required int tentatives,
  }) async {
    final headers = await _authHeaders();
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/cours/${widget.coursId}/exercices/ajouter/'),
        headers: headers,
        body: jsonEncode({
          'titre': titre,
          'enonce': enonce,
          'etoiles': etoiles,
          'duree_minutes': duree,
          'tentatives_max': tentatives,
        }),
      );
      if (response.statusCode == 201) {
        _snack('Exercice créé !');
        await _fetch();
      } else {
        final error = jsonDecode(response.body);
        _snack(error['detail'] ?? error.toString(), error: true);
      }
    } catch (e) {
      _snack('Erreur : $e', error: true);
    }
  }

  Future<List<_QuestionItem>> _fetchQuestions(int exerciceId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/exercices/$exerciceId/questions/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        return list.map(_QuestionItem.fromJson).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> _createQuestion({
    required int exerciceId,
    required String text,
    required String typeQuestion,
    required String bonneReponse,
    required int points,
    required List<Map<String, String>> choix,
  }) async {
    final headers = await _authHeaders();
    try {
      final body = <String, dynamic>{
        'text': text,
        'type_question': typeQuestion,
        'bonne_reponse': bonneReponse,
        'points': points,
      };
      if (typeQuestion == 'qcm') {
        body['choix'] = choix;
      }
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/exercices/$exerciceId/questions/ajouter/'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: error ? YekiColors.error : YekiColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? Center(
                child: CircularProgressIndicator(color: widget.courseColor),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  onRefresh: _fetch,
                  color: widget.courseColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 14),
                        _buildStarsFilter(),
                        const SizedBox(height: 20),
                        if (_filtered.isEmpty) _buildEmpty() else ..._filtered.map((ex) => _buildCard(ex)),
                      ],
                    ),
                  ),
                ),
              ),
        if (_canEdit && !_loading)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: _showCreateExerciceSheet,
              backgroundColor: widget.courseColor,
              icon: const Icon(Icons.add, color: YekiColors.white, size: 18),
              label: const Text('Ajouter', style: TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: YekiColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(
          color: YekiColors.textDark,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un exercice…',
          hintStyle: TextStyle(
            color: YekiColors.textLight.withValues(alpha: 0.55),
            fontSize: 13.5,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: widget.courseColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildStarsFilter() {
    final labels = ['Tous', 'Très facile', 'Facile', 'Moyen', 'Difficile', 'Expert'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isSelected = _etoileFilter == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _etoileFilter = index;
                _applyFilter();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? widget.courseColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? widget.courseColor.withValues(alpha: 0.35) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0) ...[
                    ...List.generate(index, (_) => const Icon(Icons.star_rounded, size: 14, color: YekiColors.gold)),
                  ],
                  const SizedBox(width: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? widget.courseColor : YekiColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(_ExerciceItem exercice) {
    final colors = [
      widget.courseColor,
      YekiColors.purple,
      YekiColors.warning,
      YekiColors.purple,
      YekiColors.info,
    ];
    final color = colors[exercice.id % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: YekiColors.primaryDark.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_outlined, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercice.titre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: YekiColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < exercice.etoiles ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: YekiColors.gold,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${exercice.nbQuestions} Q',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
          ),
          if (exercice.enonce.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                exercice.enonce,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YekiColors.textMedium,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _infoChip(Icons.timer_outlined, '${exercice.dureeMinutes} min', YekiColors.info),
                const SizedBox(width: 8),
                _infoChip(
                  Icons.repeat_outlined,
                  '${exercice.tentativesMax} essai${exercice.tentativesMax > 1 ? "s" : ""}',
                  YekiColors.warning,
                ),
                const Spacer(),
                if (_canEdit)
                  _actionBtn(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    color: YekiColors.purple,
                    onTap: () => _openQuestionsSheet(exercice),
                    outlined: true,
                  )
                else
                  _actionBtn(
                    icon: Icons.play_arrow_rounded,
                    label: 'Traiter',
                    color: color,
                    onTap: () => _ouvrirExercice(exercice),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? color.withValues(alpha: 0.08) : color,
          borderRadius: BorderRadius.circular(12),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.25), width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: outlined ? color : YekiColors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: outlined ? color : YekiColors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.courseColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: widget.courseColor.withValues(alpha: 0.12), width: 1),
              ),
              child: Icon(Icons.quiz_outlined, size: 48, color: YekiColors.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun exercice',
              style: TextStyle(fontSize: 16, color: YekiColors.textLight, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _canEdit
                  ? 'Appuyez sur + pour créer le premier exercice.'
                  : 'Aucun exercice disponible pour ce cours.',
              style: const TextStyle(fontSize: 13, color: YekiColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirExercice(_ExerciceItem exercice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasserExercicePage(
          exerciceId: exercice.id,
          coursId: int.tryParse(widget.coursId),
          coursTitre: widget.coursTitre,
        ),
      ),
    ).then((_) => _fetch());
  }

  void _showCreateExerciceSheet() {
    final titreCtrl = TextEditingController();
    final enonceCtrl = TextEditingController();
    int etoiles = 1;
    int duree = 10;
    int tentatives = 1;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: const BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () => setState(() => etoiles = index + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          index < etoiles ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: YekiColors.gold,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Durée (min)'),
                          const SizedBox(height: 6),
                          _counter(duree, 1, 180, (value) => setState(() => duree = value), widget.courseColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Tentatives max'),
                          const SizedBox(height: 6),
                          _counter(tentatives, 1, 10, (value) => setState(() => tentatives = value), YekiColors.warning),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.courseColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            if (titreCtrl.text.trim().isEmpty) {
                              _snack('Le titre est requis.', error: true);
                              return;
                            }
                            if (enonceCtrl.text.trim().isEmpty) {
                              _snack('L\'énoncé est requis.', error: true);
                              return;
                            }
                            setState(() => loading = true);
                            await _createExercice(
                              titre: titreCtrl.text.trim(),
                              enonce: enonceCtrl.text.trim(),
                              etoiles: etoiles,
                              duree: duree,
                              tentatives: tentatives,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: loading
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: YekiColors.white, strokeWidth: 2))
                        : const Text('Créer l\'exercice', style: TextStyle(color: YekiColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuestionsSheet(_ExerciceItem exercice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionsSheet(
        exercice: exercice,
        canEdit: _canEdit,
        fetchQuestions: _fetchQuestions,
        createQuestion: _createQuestion,
        courseColor: widget.courseColor,
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: YekiColors.borderLight,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _sheetTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: YekiColors.textDark),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: YekiColors.textMedium),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: YekiColors.textLight, fontSize: 13),
        filled: true,
        fillColor: YekiColors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.courseColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _counter(int value, int min, int max, void Function(int) onChange, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _counterBtn(Icons.remove, color, value > min ? () => onChange(value - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: YekiColors.textDark),
          ),
        ),
        _counterBtn(Icons.add, color, value < max ? () => onChange(value + 1) : null),
      ],
    );
  }

  Widget _counterBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.1) : YekiColors.borderLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? color : YekiColors.textLight),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  _QuestionsSheet (Design Unifié)
// ══════════════════════════════════════════════════════════════════
class _QuestionsSheet extends StatefulWidget {
  final _ExerciceItem exercice;
  final bool canEdit;
  final Future<List<_QuestionItem>> Function(int) fetchQuestions;
  final Future<bool> Function({
    required int exerciceId,
    required String text,
    required String typeQuestion,
    required String bonneReponse,
    required int points,
    required List<Map<String, String>> choix,
  }) createQuestion;
  final Color courseColor;

  const _QuestionsSheet({
    required this.exercice,
    required this.canEdit,
    required this.fetchQuestions,
    required this.createQuestion,
    required this.courseColor,
  });

  @override
  State<_QuestionsSheet> createState() => _QuestionsSheetState();
}

class _QuestionsSheetState extends State<_QuestionsSheet> {
  List<_QuestionItem> _questions = [];
  bool _loadingQ = true;
  bool _showForm = false;

  final TextEditingController _texteCtrl = TextEditingController();
  String _type = 'qcm';
  int _points = 1;

  final List<TextEditingController> _choixCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;

  final TextEditingController _bonneRepCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    _bonneRepCtrl.dispose();
    for (final ctrl in _choixCtrl) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loadingQ = true);
    final questions = await widget.fetchQuestions(widget.exercice.id);
    setState(() {
      _questions = questions;
      _loadingQ = false;
    });
  }

  void _resetForm() {
    _texteCtrl.clear();
    _bonneRepCtrl.clear();
    for (final ctrl in _choixCtrl) {
      ctrl.clear();
    }
    while (_choixCtrl.length > 2) {
      _choixCtrl.removeLast();
    }
    setState(() {
      _type = 'qcm';
      _points = 1;
      _correctIndex = 0;
      _showForm = false;
    });
  }

  Future<void> _submit() async {
    final texte = _texteCtrl.text.trim();
    if (texte.isEmpty) {
      _snack('L\'énoncé est requis.', error: true);
      return;
    }

    String bonneReponse;
    List<Map<String, String>> choix = [];

    if (_type == 'qcm') {
      if (_choixCtrl.any((ctrl) => ctrl.text.trim().isEmpty)) {
        _snack('Remplissez tous les choix.', error: true);
        return;
      }
      if (_correctIndex >= _choixCtrl.length) {
        _snack('Sélectionnez la bonne réponse.', error: true);
        return;
      }
      bonneReponse = _choixCtrl[_correctIndex].text.trim();
      choix = _choixCtrl.map((ctrl) => {'texte': ctrl.text.trim()}).toList();
    } else {
      bonneReponse = _bonneRepCtrl.text.trim();
      if (bonneReponse.isEmpty) {
        _snack('Indiquez la bonne réponse.', error: true);
        return;
      }
    }

    setState(() => _submitting = true);

    final success = await widget.createQuestion(
      exerciceId: widget.exercice.id,
      text: texte,
      typeQuestion: _type,
      bonneReponse: bonneReponse,
      points: _points,
      choix: choix,
    );

    setState(() => _submitting = false);

    if (success) {
      _snack('Question ajoutée !');
      _resetForm();
      _loadQuestions();
    } else {
      _snack('Erreur lors de l\'envoi.', error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: error ? YekiColors.error : YekiColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.93,
      ),
      decoration: const BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Divider(color: YekiColors.borderLight, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                children: [
                  if (_showForm) _buildForm(),
                  if (_loadingQ)
                    const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
                  else if (_questions.isEmpty && !_showForm)
                    _buildEmptyState()
                  else
                    ..._questions.asMap().entries.map((entry) => _buildQuestionCard(entry.key + 1, entry.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: YekiColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: YekiColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_outlined, color: YekiColors.purple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercice.titre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_questions.length} question${_questions.length != 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 12, color: YekiColors.textLight),
                    ),
                  ],
                ),
              ),
              if (widget.canEdit && !_showForm)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.add, size: 16, color: YekiColors.white),
                  label: const Text('Ajouter', style: TextStyle(color: YekiColors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YekiColors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: YekiColors.purple.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.purple.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nouvelle question',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: YekiColors.purple),
              ),
              IconButton(
                onPressed: _resetForm,
                icon: const Icon(Icons.close),
                color: YekiColors.textLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionLabel('Type de question'),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeBtn('qcm', 'QCM', Icons.check_box_outlined),
              const SizedBox(width: 10),
              _typeBtn('texte', 'Texte libre', Icons.text_fields),
            ],
          ),
          const SizedBox(height: 18),
          _sectionLabel('Énoncé de la question'),
          const SizedBox(height: 8),
          TextField(
            controller: _texteCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
            decoration: _inputDeco('Écrivez la question ici…'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _sectionLabel('Points :'),
              const SizedBox(width: 12),
              _smallCounter(),
            ],
          ),
          const SizedBox(height: 18),
          if (_type == 'qcm') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Choix de réponses'),
                if (_choixCtrl.length < 6)
                  TextButton.icon(
                    onPressed: () => setState(() => _choixCtrl.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 15, color: YekiColors.purple),
                    label: const Text('Ajouter un choix', style: TextStyle(color: YekiColors.purple, fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cochez (●) le choix correct',
              style: TextStyle(fontSize: 11, color: YekiColors.textLight),
            ),
            const SizedBox(height: 10),
            ...List.generate(_choixCtrl.length, (index) => _buildChoixRow(index)),
            if (_choixCtrl.length > 2) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _choixCtrl.last.dispose();
                      _choixCtrl.removeLast();
                      if (_correctIndex >= _choixCtrl.length) {
                        _correctIndex = _choixCtrl.length - 1;
                      }
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 14, color: YekiColors.error),
                  label: const Text('Supprimer le dernier', style: TextStyle(color: YekiColors.error, fontSize: 12)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
            ],
          ],
          if (_type == 'texte') ...[
            _sectionLabel('Réponse attendue (correction auto)'),
            const SizedBox(height: 8),
            TextField(
              controller: _bonneRepCtrl,
              style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
              decoration: _inputDeco('Tapez la bonne réponse exacte…'),
            ),
            const SizedBox(height: 6),
            Text(
              'La réponse de l\'apprenant sera comparée à ce texte (insensible à la casse).',
              style: TextStyle(fontSize: 11, color: YekiColors.textLight),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: YekiColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: YekiColors.white, strokeWidth: 2))
                  : const Text('Publier la question', style: TextStyle(color: YekiColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoixRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _correctIndex = index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _correctIndex == index ? YekiColors.purple : YekiColors.white,
                border: Border.all(
                  color: _correctIndex == index ? YekiColors.purple : YekiColors.borderLight,
                  width: 2,
                ),
              ),
              child: _correctIndex == index ? const Icon(Icons.check, color: YekiColors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _choixCtrl[index],
              style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
              decoration: _inputDeco('Choix ${index + 1}').copyWith(isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int number, _QuestionItem question) {
    final isQcm = question.typeQuestion == 'qcm';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YekiColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$number',
                  style: const TextStyle(color: YekiColors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isQcm ? YekiColors.info.withValues(alpha: 0.08) : YekiColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isQcm ? 'QCM' : 'Texte libre',
                  style: TextStyle(
                    color: isQcm ? YekiColors.info : YekiColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_outlined, size: 14, color: YekiColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    '${question.points} pt${question.points > 1 ? "s" : ""}',
                    style: TextStyle(fontSize: 12, color: YekiColors.textLight, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark),
          ),
          const SizedBox(height: 12),
          if (isQcm && question.choix.isNotEmpty)
            ...question.choix.map((choix) {
              final isCorrect = choix == question.bonneReponse;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? YekiColors.success.withValues(alpha: 0.06) : YekiColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect ? YekiColors.success.withValues(alpha: 0.2) : YekiColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isCorrect ? YekiColors.success : YekiColors.textLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        choix,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCorrect ? const Color(0xFF059669) : YekiColors.textMedium,
                          fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (!isQcm && question.bonneReponse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: YekiColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: YekiColors.success.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: YekiColors.success, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'Réponse : ${question.bonneReponse}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 56, color: YekiColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Aucune question pour l\'instant.',
            style: TextStyle(color: YekiColors.textLight, fontWeight: FontWeight.w500),
          ),
          if (widget.canEdit) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add, color: YekiColors.white, size: 16),
              label: const Text('Créer la première question', style: TextStyle(color: YekiColors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: YekiColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeBtn(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? YekiColors.purple : YekiColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? YekiColors.purple : YekiColors.borderLight, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? YekiColors.white : YekiColors.textMedium),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? YekiColors.white : YekiColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallCounter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _counterBtn(Icons.remove, _points > 1 ? () => setState(() => _points--) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$_points pt',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: YekiColors.textDark),
          ),
        ),
        _counterBtn(Icons.add, _points < 10 ? () => setState(() => _points++) : null),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? YekiColors.purple.withValues(alpha: 0.08) : YekiColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? YekiColors.purple : YekiColors.textLight),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: YekiColors.textMedium),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: YekiColors.textLight, fontSize: 13),
      filled: true,
      fillColor: YekiColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: YekiColors.purple, width: 1.5),
      ),
    );
  }
}