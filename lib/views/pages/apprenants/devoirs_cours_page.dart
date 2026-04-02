// lib/views/pages/apprenants/devoirs_cours_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

// ============================================================
// CONSTANTES
// ============================================================
const String _base = 'https://yeki.pythonanywhere.com/api';
const Color _teal = Color(0xFF2884A0);
const Color _dark = Color(0xFF0D1B2A);
const Color _bg = Color(0xFFF8FAFC);
const Color _green = Color(0xFF10B981);
const Color _orange = Color(0xFFF97316);
const Color _red = Color(0xFFEF4444);
const Color _gold = Color(0xFFE2A84B);
const Color _purple = Color(0xFF8B5CF6);

// ============================================================
// HELPERS
// ============================================================
Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ============================================================
// MODÈLE DEVOIR
// ============================================================
class DevoirCours {
  final int id;
  final String titre, description, dateDebut, dateLimite;
  final bool estOuvert, estExpire;
  final String? statut;
  final double? note;
  final double noteSur;
  final int nbQuestions, dureeMinutes, tentativesMax;
  final String typeCorrection;
  final bool estPublie;

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
    this.typeCorrection = 'auto',
    this.estPublie = true,
    this.dureeMinutes = 60,
    this.tentativesMax = 1,
  });

  factory DevoirCours.fromJson(Map<String, dynamic> j) => DevoirCours(
    id: j['id'],
    titre: j['titre'] ?? '',
    description: j['description'] ?? '',
    dateDebut: j['date_debut'] ?? '',
    dateLimite: j['date_limite'] ?? '',
    estOuvert: j['est_ouvert'] ?? false,
    estExpire: j['est_expire'] ?? false,
    statut: j['ma_soumission']?['statut'],
    note: j['ma_soumission']?['note'] != null
        ? (j['ma_soumission']['note'] as num).toDouble()
        : null,
    noteSur: (j['note_sur'] as num? ?? 20).toDouble(),
    nbQuestions: j['nb_questions'] ?? 0,
    typeCorrection: j['type_correction'] ?? 'auto',
    estPublie: j['est_publie'] ?? true,
    dureeMinutes: j['duree_minutes'] ?? 60,
    tentativesMax: j['tentatives_max'] ?? 1,
  );

  bool get aSoumis => statut != null;
  bool get estCorrige => statut == 'corrige';
}

// ============================================================
// MODÈLE SOUMISSION
// ============================================================
class SoumissionItem {
  final int id, nbFocusPerdu;
  final String apprenantNom, apprenantUsername, statut, soumisLe;
  final double? note;
  final bool estSuspecte;

  SoumissionItem({
    required this.id,
    required this.apprenantNom,
    required this.apprenantUsername,
    required this.statut,
    this.note,
    required this.soumisLe,
    required this.estSuspecte,
    required this.nbFocusPerdu,
  });

  factory SoumissionItem.fromJson(Map<String, dynamic> j) => SoumissionItem(
    id: j['id'],
    apprenantNom: j['apprenant_nom'] ?? '',
    apprenantUsername: j['apprenant_username'] ?? '',
    statut: j['statut'] ?? '',
    note: j['note'] != null ? (j['note'] as num).toDouble() : null,
    soumisLe: j['soumis_le'] ?? '',
    estSuspecte: j['est_suspecte'] ?? false,
    nbFocusPerdu: j['nb_focus_perdu'] ?? 0,
  );
}

// ============================================================
// MODÈLE QUESTION DEVOIR
// ============================================================
class QuestionDevoirItem {
  final int id, points, ordre;
  final String texte, typeQuestion;
  final List<ChoixItem> choix;

  QuestionDevoirItem({
    required this.id,
    required this.texte,
    required this.typeQuestion,
    required this.points,
    required this.ordre,
    required this.choix,
  });

  factory QuestionDevoirItem.fromJson(Map<String, dynamic> j) => QuestionDevoirItem(
    id: j['id'],
    texte: j['texte'] ?? '',
    typeQuestion: j['type_question'] ?? 'qcm',
    points: j['points'] ?? 1,
    ordre: j['ordre'] ?? 1,
    choix: (j['choix'] as List? ?? []).map((c) => ChoixItem.fromJson(c)).toList(),
  );
}

class ChoixItem {
  final int id;
  final String texte;
  final bool estCorrect;

  ChoixItem({required this.id, required this.texte, required this.estCorrect});

  factory ChoixItem.fromJson(Map<String, dynamic> j) => ChoixItem(
    id: j['id'],
    texte: j['texte'] ?? '',
    estCorrect: j['est_correct'] ?? false,
  );
}

// ============================================================
// PAGE PRINCIPALE DES DEVOIRS
// ============================================================
class DevoirsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final bool isEnseignantPrincipal;
  final void Function(int questionId)? onNaviguerForum;

  const DevoirsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.isEnseignantPrincipal = false,
    this.onNaviguerForum,
  });

  @override
  State<DevoirsCoursPage> createState() => _DevoirsCoursPageState();
}

class _DevoirsCoursPageState extends State<DevoirsCoursPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<DevoirCours> _devoirs = [];
  String _filtreStatut = 'tous';
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT DES DEVOIRS
  // ============================================================
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_base/cours/${widget.coursId}/devoirs/'),
        headers: _headers(token),
      );

      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => DevoirCours.fromJson(j as Map<String, dynamic>))
            .toList();

        setState(() {
          _devoirs = data;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      } else {
        setState(() => _loading = false);
        if (res.statusCode != 404) {
          _snack('Erreur ${res.statusCode}', error: true);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      _snack('Erreur réseau', error: true);
    }
  }

  // ============================================================
  // FILTRES
  // ============================================================
  List<DevoirCours> get _filtres {
    if (_filtreStatut == 'tous') return _devoirs;
    if (_filtreStatut == 'non_commence')
      return _devoirs.where((d) => !d.aSoumis).toList();
    return _devoirs.where((d) => d.statut == _filtreStatut).toList();
  }

  // ============================================================
  // DÉMARRER UN DEVOIR
  // ============================================================
  Future<void> _demarrerDevoir(DevoirCours d) async {
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('$_base/devoirs/${d.id}/demarrer/'),
        headers: _headers(token),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComposerDevoirPage(
              devoirId: d.id,
              titre: d.titre,
              dureeMin: d.dureeMinutes,
              noteSur: d.noteSur.toInt(),
            ),
          ),
        ).then((_) => _charger());
      } else {
        final err = jsonDecode(res.body);
        _snack(err['detail'] ?? 'Erreur lors du démarrage', error: true);
      }
    } catch (_) {
      _snack('Erreur réseau', error: true);
    }
  }

  // ============================================================
  // DIALOGUE DE CONFIRMATION
  // ============================================================
  Future<void> _confirmerDemarrage(DevoirCours d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(d.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogInfo(Icons.timer_rounded, 'Durée : ${d.dureeMinutes} minutes'),
            _dialogInfo(Icons.quiz_rounded, '${d.nbQuestions} questions'),
            _dialogInfo(Icons.grade_rounded, 'Note sur ${d.noteSur.toStringAsFixed(0)}'),
            _dialogInfo(Icons.refresh_rounded, '${d.tentativesMax} tentative(s) max'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _orange, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Une fois démarré, le chronomètre se lance.',
                      style: TextStyle(fontSize: 12, color: _orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Commencer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) _demarrerDevoir(d);
  }

  Widget _dialogInfo(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: _teal),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================
  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _red : _green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  (String, Color) _getStatusInfo(DevoirCours d) {
    if (d.estCorrige) return ('Corrigé', _green);
    if (d.statut == 'soumis') return ('Soumis', _orange);
    if (d.statut == 'en_cours') return ('En cours', _purple);
    if (d.statut == 'en_retard') return ('En retard', _red);
    if (d.estExpire) return ('Expiré', _red);
    if (d.estOuvert) return ('Ouvert', _teal);
    return ('À venir', Colors.grey);
  }

  // ============================================================
  // WIDGETS UI
  // ============================================================
  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ],
    ),
  );

  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );

  Widget _solidBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _outlineBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );

  // ============================================================
  // BARRE DE FILTRES
  // ============================================================
  Widget _buildFilters() {
    final filters = [
      ('tous', 'Tous', null),
      ('non_commence', 'À faire', _orange),
      ('en_cours', 'En cours', _purple),
      ('soumis', 'Soumis', _teal),
      ('corrige', 'Corrigés', _green),
      ('en_retard', 'En retard', _red),
    ];

    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: filters.map((f) {
                  final sel = _filtreStatut == f.$1;
                  final col = f.$3 ?? _teal;
                  return GestureDetector(
                    onTap: () => setState(() => _filtreStatut = f.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? col : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: sel ? col : Colors.grey.shade200),
                        boxShadow: sel ? [BoxShadow(color: col.withOpacity(0.25), blurRadius: 8)] : [],
                      ),
                      child: Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _dark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${_filtres.length}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS PAR STATUT
  // ============================================================
  Widget _buildActions(DevoirCours d) {
    // Vue enseignant
    if (widget.isEnseignantPrincipal) {
      return Row(
        children: [
          Expanded(
            child: _outlineBtn('Questions', Icons.quiz_rounded, _teal, () {
              _showQuestionsSheet(d);
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _solidBtn('Soumissions', Icons.people_rounded, _purple, () {
              _showGestionSoumissions(d);
            }),
          ),
        ],
      );
    }

    // Vue apprenant - Devoir corrigé
    if (d.estCorrige) {
      return Row(
        children: [
          Expanded(
            child: _solidBtn(
              'Voir les résultats',
              Icons.bar_chart_rounded,
              _green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultatDevoirPage(
                    devoirId: d.id,
                    titre: d.titre,
                    coursId: int.tryParse(widget.coursId),
                    coursTitre: widget.coursTitre,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.help_outline_rounded, _teal, () {
            ouvrirPreoccupation(
              context: context,
              source: 'devoir',
              devoirId: d.id,
              devoirTitre: d.titre,
              coursId: int.tryParse(widget.coursId),
              coursTitre: widget.coursTitre,
            );
          }),
        ],
      );
    }

    // Vue apprenant - Devoir soumis en attente
    if (d.aSoumis && !d.estCorrige) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded, color: _orange, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'En attente de correction',
                    style: TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.help_outline_rounded, _teal, () {
            ouvrirPreoccupation(
              context: context,
              source: 'devoir',
              devoirId: d.id,
              devoirTitre: d.titre,
              coursId: int.tryParse(widget.coursId),
              coursTitre: widget.coursTitre,
            );
          }),
        ],
      );
    }

    // Vue apprenant - Devoir non disponible
    if (!d.estOuvert || d.estExpire) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, color: Colors.grey.shade400, size: 16),
            const SizedBox(width: 6),
            Text(
              d.estExpire ? 'Devoir expiré' : 'Non disponible',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Vue apprenant - Devoir disponible
    return _solidBtn('Commencer le devoir', Icons.play_arrow_rounded, _teal, () => _confirmerDemarrage(d));
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _teal.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_outlined, size: 48, color: _teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun devoir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les devoirs créés par l\'enseignant apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GESTION DES QUESTIONS (ENSEIGNANT)
  // ============================================================
  void _showQuestionsSheet(DevoirCours d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionsSheet(devoirId: d.id, devoir: d),
    ).then((_) => _charger());
  }

  // ============================================================
  // GESTION DES SOUMISSIONS (ENSEIGNANT)
  // ============================================================
  void _showGestionSoumissions(DevoirCours d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GestionSoumissionsSheet(
        devoir: d,
        noteSur: d.noteSur,
        fetchSoumissions: () => _fetchSoumissions(d.id),
        corrigerSoumission: _corrigerSoumission,
      ),
    ).then((_) => _charger());
  }

  Future<List<SoumissionItem>> _fetchSoumissions(int devoirId) async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/devoirs/$devoirId/soumissions/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((j) => SoumissionItem.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> _corrigerSoumission(int soumId, double note, String commentaire) async {
    final token = await _getToken();
    try {
      final res = await http.patch(
        Uri.parse('$_base/soumissions/$soumId/corriger/'),
        headers: _headers(token),
        body: jsonEncode({'note': note, 'commentaire': commentaire}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }

    if (_devoirs.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _filtres.length,
            itemBuilder: (context, index) {
              final d = _filtres[index];
              final statusInfo = _getStatusInfo(d);
              final delay = (index * 0.06).clamp(0.0, 1.0);
              final anim = CurvedAnimation(
                parent: _animCtrl,
                curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _teal.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: statusInfo.$2,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusInfo.$2.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.assignment_rounded, color: statusInfo.$2, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.titre,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _dark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          d.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(statusInfo.$1, statusInfo.$2),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _infoChip(Icons.calendar_today_rounded, _formatDate(d.dateLimite), d.estExpire ? _red : _orange),
                                  _infoChip(Icons.timer_rounded, '${d.dureeMinutes}min', _teal),
                                  _infoChip(Icons.quiz_rounded, '${d.nbQuestions} question${d.nbQuestions > 1 ? 's' : ''}', _purple),
                                  _infoChip(Icons.grade_rounded, '/${d.noteSur.toStringAsFixed(0)}', _gold),
                                ],
                              ),
                              if (d.estCorrige && d.note != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _green.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.grade_rounded, color: _green, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Note : ${d.note!.toStringAsFixed(1)} / ${d.noteSur.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: _dark, fontSize: 15),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(100)),
                                        child: Text(
                                          '${(d.note! / d.noteSur * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              _buildActions(d),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SHEET GESTION DES QUESTIONS (ENSEIGNANT)
// ============================================================
class _QuestionsSheet extends StatefulWidget {
  final int devoirId;
  final DevoirCours devoir;

  const _QuestionsSheet({required this.devoirId, required this.devoir});

  @override
  State<_QuestionsSheet> createState() => _QuestionsSheetState();
}

class _QuestionsSheetState extends State<_QuestionsSheet> {
  bool _loading = true;
  List<QuestionDevoirItem> _questions = [];
  bool _showForm = false;

  final _texteCtrl = TextEditingController();
  String _type = 'qcm';
  int _points = 1;
  List<TextEditingController> _choixCtrl = [
    TextEditingController(), TextEditingController()
  ];
  List<bool> _choixCorrect = [false, false];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    for (final c in _choixCtrl) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/devoirs/${widget.devoirId}/questions/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _questions = (jsonDecode(res.body) as List)
              .map((j) => QuestionDevoirItem.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _ajouterQuestion() async {
    if (_texteCtrl.text.trim().isEmpty) return;

    final token = await _getToken();
    final body = <String, dynamic>{
      'texte': _texteCtrl.text.trim(),
      'type_question': _type,
      'points': _points,
      'ordre': _questions.length + 1,
    };

    if (_type == 'qcm') {
      body['choix'] = _choixCtrl.asMap().entries
          .where((e) => e.value.text.isNotEmpty)
          .map((e) => {'texte': e.value.text, 'est_correct': _choixCorrect[e.key]})
          .toList();
    }

    try {
      final res = await http.post(
        Uri.parse('$_base/devoirs/${widget.devoirId}/questions/ajouter/'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        _texteCtrl.clear();
        for (final c in _choixCtrl) c.clear();
        _choixCorrect = [false, false];
        setState(() => _showForm = false);
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.quiz_rounded, color: _teal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            widget.devoir.titre,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_questions.length} question${_questions.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      ..._questions.asMap().entries.map((e) => _buildQuestionCard(e.value, e.key + 1)),
                      if (!_showForm)
                        GestureDetector(
                          onTap: () => setState(() => _showForm = true),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _teal.withOpacity(0.2), style: BorderStyle.solid),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: _teal, size: 20),
                                SizedBox(width: 8),
                                Text('Ajouter une question', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 14)),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildFormulaireQuestion(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionDevoirItem q, int num) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Q$num', style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  q.typeQuestion.toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _gold.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${q.points} pt', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.texte, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (q.typeQuestion == 'qcm') ...[
            const SizedBox(height: 8),
            ...q.choix.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    c.estCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: c.estCorrect ? _green : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.texte,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.estCorrect ? _green : Colors.grey.shade700,
                        fontWeight: c.estCorrect ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulaireQuestion() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouvelle question', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _dark)),
          const SizedBox(height: 12),
          Row(
            children: [
              _typeBtn('qcm', 'QCM', Icons.list_alt_rounded),
              const SizedBox(width: 8),
              _typeBtn('texte', 'Texte libre', Icons.text_fields_rounded),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _texteCtrl,
            maxLines: 2,
            decoration: _inputDeco('Énoncé de la question'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Points :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 12),
              _cBtn(Icons.remove, _teal, _points > 1 ? () => setState(() => _points--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_points', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              _cBtn(Icons.add, _teal, _points < 20 ? () => setState(() => _points++) : null),
            ],
          ),
          if (_type == 'qcm') ...[
            const SizedBox(height: 10),
            ..._choixCtrl.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      for (int i = 0; i < _choixCorrect.length; i++) _choixCorrect[i] = false;
                      _choixCorrect[e.key] = true;
                    }),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _choixCorrect[e.key] ? _green : Colors.transparent,
                        border: Border.all(color: _choixCorrect[e.key] ? _green : Colors.grey.shade300, width: 2),
                      ),
                      child: _choixCorrect[e.key] ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      decoration: _inputDeco('Choix ${String.fromCharCode(65 + e.key)}'),
                    ),
                  ),
                ],
              ),
            )),
            TextButton.icon(
              onPressed: () => setState(() {
                _choixCtrl.add(TextEditingController());
                _choixCorrect.add(false);
              }),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Ajouter un choix', style: TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Annuler'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _ajouterQuestion,
                icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                label: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String val, String label, IconData icon) {
    final sel = _type == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _teal : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: sel ? Colors.white : Colors.grey.shade500),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cBtn(IconData icon, Color col, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: onTap != null ? col.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: onTap != null ? col : Colors.grey.shade400),
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal)),
  );
}

// ============================================================
// SHEET GESTION DES SOUMISSIONS (ENSEIGNANT)
// ============================================================
class _GestionSoumissionsSheet extends StatefulWidget {
  final DevoirCours devoir;
  final double noteSur;
  final Future<List<SoumissionItem>> Function() fetchSoumissions;
  final Future<bool> Function(int, double, String) corrigerSoumission;

  const _GestionSoumissionsSheet({
    required this.devoir,
    required this.noteSur,
    required this.fetchSoumissions,
    required this.corrigerSoumission,
  });

  @override
  State<_GestionSoumissionsSheet> createState() => _GestionSoumissionsSheetState();
}

class _GestionSoumissionsSheetState extends State<_GestionSoumissionsSheet>
    with SingleTickerProviderStateMixin {
  List<SoumissionItem> _soumissions = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _soumissions = await widget.fetchSoumissions();
    if (mounted) setState(() => _loading = false);
  }

  List<SoumissionItem> get _aCorriger =>
      _soumissions.where((s) => s.statut == 'soumis' || s.statut == 'en_retard').toList();

  List<SoumissionItem> get _corriges =>
      _soumissions.where((s) => s.statut == 'corrige').toList();

  Color _col(String s) {
    switch (s) {
      case 'corrige': return _green;
      case 'soumis': return _orange;
      case 'en_retard': return _red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.people_alt_outlined, color: _purple, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Soumissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            widget.devoir.titre,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!_loading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${_soumissions.length} soumis',
                          style: const TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  labelColor: _teal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _teal,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(text: 'Tous (${_soumissions.length})'),
                    Tab(text: 'À corriger (${_aCorriger.length})'),
                    Tab(text: 'Corrigés (${_corriges.length})'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _listeSoumissions(_soumissions),
                      _listeSoumissions(_aCorriger),
                      _listeSoumissions(_corriges),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _listeSoumissions(List<SoumissionItem> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Aucune soumission', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildSoumissionCard(list[i]),
    );
  }

  Widget _buildSoumissionCard(SoumissionItem s) {
    final col = _col(s.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: col.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                s.apprenantNom.isNotEmpty ? s.apprenantNom[0].toUpperCase() : '?',
                style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.apprenantNom.isNotEmpty ? s.apprenantNom : s.apprenantUsername,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (s.note != null)
                  Text(
                    'Note : ${s.note!.toStringAsFixed(1)} / ${widget.noteSur.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w600),
                  )
                else
                  Text(s.statut, style: TextStyle(fontSize: 12, color: col)),
              ],
            ),
          ),
          if (s.statut == 'soumis' || s.statut == 'en_retard')
            GestureDetector(
              onTap: () => _showCorrectionDialog(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
                child: const Text('Corriger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          if (s.estSuspecte)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: const Icon(Icons.warning_rounded, color: _red, size: 18),
            ),
        ],
      ),
    );
  }

  void _showCorrectionDialog(SoumissionItem s) {
    double note = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Corriger : ${s.apprenantNom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (_, setS) => Column(
                children: [
                  Text(
                    '${note.toStringAsFixed(1)} / ${widget.noteSur.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _teal),
                  ),
                  Slider(
                    value: note,
                    min: 0,
                    max: widget.noteSur,
                    divisions: (widget.noteSur * 2).toInt(),
                    activeColor: _teal,
                    onChanged: (v) => setS(() => note = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Commentaire (optionnel)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _teal, elevation: 0),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.corrigerSoumission(s.id, note, commentCtrl.text);
              if (ok) _load();
            },
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}