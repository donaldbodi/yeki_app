// lib/views/pages/apprenants/devoirs_cours_page.dart
// ═══════════════════════════════════════════════════════════════
//  YEKI DEVOIRS DU COURS — Design Unifié Premium
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

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
// PAGE PRINCIPALE DES DEVOIRS
// ============================================================
class DevoirsCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final bool isEnseignantPrincipal;
  final void Function(int questionId)? onNaviguerForum;
  final Color courseColor;

  const DevoirsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.isEnseignantPrincipal = false,
    this.onNaviguerForum,
    required this.courseColor,
  });

  @override
  State<DevoirsCoursPage> createState() => _DevoirsCoursPageState();
}

class _DevoirsCoursPageState extends State<DevoirsCoursPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<DevoirCours> _devoirs = [];
  String _filtreStatut = 'tous';
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _charger();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cours/${widget.coursId}/devoirs/'),
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
        _animCtrl.forward(from: 0.0);
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

  List<DevoirCours> get _filtres {
    if (_filtreStatut == 'tous') return _devoirs;
    if (_filtreStatut == 'non_commence') {
      return _devoirs.where((d) => !d.aSoumis).toList();
    }
    return _devoirs.where((d) => d.statut == _filtreStatut).toList();
  }

  Future<void> _demarrerDevoir(DevoirCours d) async {
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/devoirs/${d.id}/demarrer/'),
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

  Future<void> _confirmerDemarrage(DevoirCours d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: Text(d.titre,
            style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.textDark)),
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
                color: YekiColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: YekiColors.warning.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: YekiColors.warning, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Une fois démarré, le chronomètre se lance.',
                      style: TextStyle(fontSize: 12, color: YekiColors.warning),
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
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.courseColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Commencer', style: TextStyle(color: YekiColors.white)),
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
            Icon(icon, size: 14, color: widget.courseColor),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 13, color: YekiColors.textMedium)),
          ],
        ),
      );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: error ? YekiColors.error : YekiColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    if (d.estCorrige) return ('Corrigé', YekiColors.success);
    if (d.statut == 'soumis') return ('Soumis', YekiColors.warning);
    if (d.statut == 'en_cours') return ('En cours', YekiColors.purple);
    if (d.statut == 'en_retard') return ('En retard', YekiColors.error);
    if (d.estExpire) return ('Expiré', YekiColors.error);
    if (d.estOuvert) return ('Ouvert', widget.courseColor);
    return ('À venir', YekiColors.textLight);
  }

  Widget _buildFilters() {
    final filters = [
      ('tous', 'Tous', null),
      ('non_commence', 'À faire', YekiColors.warning),
      ('en_cours', 'En cours', YekiColors.purple),
      ('soumis', 'Soumis', widget.courseColor),
      ('corrige', 'Corrigés', YekiColors.success),
      ('en_retard', 'En retard', YekiColors.error),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final sel = _filtreStatut == f.$1;
            final col = f.$3 ?? widget.courseColor;
            return GestureDetector(
              onTap: () => setState(() => _filtreStatut = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? col.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? col.withValues(alpha: 0.35) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                    color: sel ? col : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActions(DevoirCours d) {
    if (widget.isEnseignantPrincipal) {
      return Row(
        children: [
          Expanded(
            child: _actionBtn(
              'Questions',
              Icons.quiz_rounded,
              widget.courseColor,
              () => _showQuestionsSheet(d),
              outlined: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'Soumissions',
              Icons.people_rounded,
              YekiColors.purple,
              () => _showGestionSoumissions(d),
            ),
          ),
        ],
      );
    }

    if (d.estCorrige) {
      return Row(
        children: [
          Expanded(
            child: _actionBtn(
              'Voir les résultats',
              Icons.bar_chart_rounded,
              YekiColors.success,
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
          _iconBtn(Icons.help_outline_rounded, widget.courseColor, () {
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

    if (d.aSoumis && !d.estCorrige) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: YekiColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YekiColors.warning.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_top_rounded, color: YekiColors.warning, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'En attente de correction',
                    style: TextStyle(color: YekiColors.warning, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.help_outline_rounded, widget.courseColor, () {
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

    if (!d.estOuvert || d.estExpire) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: YekiColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YekiColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_rounded, size: 16, color: YekiColors.textLight),
            const SizedBox(width: 6),
            Text(
              d.estExpire ? 'Devoir expiré' : 'Non disponible',
              style: TextStyle(color: YekiColors.textLight, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return _actionBtn(
      'Commencer le devoir',
      Icons.play_arrow_rounded,
      widget.courseColor,
      () => _confirmerDemarrage(d),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: outlined ? color.withValues(alpha: 0.08) : color,
          borderRadius: BorderRadius.circular(12),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: outlined ? color : YekiColors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: outlined ? color : YekiColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.courseColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: widget.courseColor.withValues(alpha: 0.12), width: 1),
              ),
              child: Icon(Icons.assignment_outlined, size: 48, color: widget.courseColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun devoir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: YekiColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les devoirs créés par l\'enseignant apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: YekiColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionsSheet(DevoirCours d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionsSheet(
        devoirId: d.id,
        devoir: d,
        courseColor: widget.courseColor,
      ),
    ).then((_) => _charger());
  }

  void _showGestionSoumissions(DevoirCours d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GestionSoumissionsSheet(
        devoir: d,
        noteSur: d.noteSur,
        courseColor: widget.courseColor,
        fetchSoumissions: () => _fetchSoumissions(d.id),
        corrigerSoumission: _corrigerSoumission,
      ),
    ).then((_) => _charger());
  }

  Future<List<SoumissionItem>> _fetchSoumissions(int devoirId) async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devoirs/$devoirId/soumissions/'),
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
        Uri.parse('${ApiConstants.baseUrl}/soumissions/$soumId/corriger/'),
        headers: _headers(token),
        body: jsonEncode({'note': note, 'commentaire': commentaire}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.courseColor));
    }

    if (_devoirs.isEmpty) {
      return _buildEmpty();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _filtres.length,
              itemBuilder: (context, index) {
                final d = _filtres[index];
                return _buildDevoirCard(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevoirCard(DevoirCours d) {
    final statusInfo = _getStatusInfo(d);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: YekiColors.primaryDark.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
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
                    color: statusInfo.$2.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_rounded, color: statusInfo.$2, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.titre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: YekiColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.$2.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusInfo.$2.withValues(alpha: 0.15), width: 0.5),
                  ),
                  child: Text(
                    statusInfo.$1,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusInfo.$2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _infoChip(Icons.calendar_today_rounded, _formatDate(d.dateLimite),
                    d.estExpire ? YekiColors.error : YekiColors.warning),
                _infoChip(Icons.timer_rounded, '${d.dureeMinutes}min', widget.courseColor),
                _infoChip(Icons.quiz_rounded, '${d.nbQuestions} question${d.nbQuestions > 1 ? 's' : ''}',
                    YekiColors.purple),
                _infoChip(Icons.grade_rounded, '/${d.noteSur.toStringAsFixed(0)}', YekiColors.gold),
              ],
            ),
          ),
          if (d.estCorrige && d.note != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YekiColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.success.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grade_rounded, color: YekiColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Note : ${d.note!.toStringAsFixed(1)} / ${d.noteSur.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: YekiColors.textDark, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: YekiColors.success, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${((d.note! / d.noteSur) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildActions(d),
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
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
// SHEET GESTION DES QUESTIONS (suite à implémenter si besoin)
// ============================================================
class _QuestionsSheet extends StatefulWidget {
  final int devoirId;
  final DevoirCours devoir;
  final Color courseColor;

  const _QuestionsSheet({
    required this.devoirId,
    required this.devoir,
    required this.courseColor,
  });

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
  final List<TextEditingController> _choixCtrl = [TextEditingController(), TextEditingController()];
  List<bool> _choixCorrect = [false, false];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    for (final c in _choixCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devoirs/${widget.devoirId}/questions/'),
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
          .map((e) => {
                'texte': e.value.text,
                'est_correct': _choixCorrect[e.key],
              })
          .toList();
    }

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/devoirs/${widget.devoirId}/questions/ajouter/'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        _texteCtrl.clear();
        for (final c in _choixCtrl) {
          c.clear();
        }
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
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.courseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.quiz_rounded, color: widget.courseColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Questions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
                          Text(
                            widget.devoir.titre,
                            style: TextStyle(fontSize: 12, color: YekiColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_questions.length} question${_questions.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: widget.courseColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
                              color: widget.courseColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: widget.courseColor.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: widget.courseColor, size: 20),
                                const SizedBox(width: 8),
                                Text('Ajouter une question',
                                    style: TextStyle(color: widget.courseColor, fontWeight: FontWeight.w700, fontSize: 14)),
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
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(14),
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
                  color: widget.courseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Q$num',
                    style: TextStyle(color: widget.courseColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YekiColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  q.typeQuestion.toUpperCase(),
                  style: TextStyle(color: YekiColors.info, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YekiColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${q.points} pt',
                    style: TextStyle(color: YekiColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.texte,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
          if (q.typeQuestion == 'qcm') ...[
            const SizedBox(height: 8),
            ...q.choix.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        c.estCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: c.estCorrect ? YekiColors.success : YekiColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.texte,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.estCorrect ? YekiColors.success : YekiColors.textMedium,
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
        color: YekiColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.courseColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouvelle question',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: YekiColors.textDark)),
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
              const Text('Points :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: YekiColors.textMedium)),
              const SizedBox(width: 12),
              _cBtn(Icons.remove, widget.courseColor, _points > 1 ? () => setState(() => _points--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_points',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
              ),
              _cBtn(Icons.add, widget.courseColor, _points < 20 ? () => setState(() => _points++) : null),
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
                          for (int i = 0; i < _choixCorrect.length; i++) {
                            _choixCorrect[i] = false;
                          }
                          _choixCorrect[e.key] = true;
                        }),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _choixCorrect[e.key] ? YekiColors.success : Colors.transparent,
                            border: Border.all(
                                color: _choixCorrect[e.key] ? YekiColors.success : YekiColors.borderLight, width: 2),
                          ),
                          child: _choixCorrect[e.key]
                              ? const Icon(Icons.check, size: 12, color: YekiColors.white)
                              : null,
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
              icon: const Icon(Icons.add, size: 14, color: YekiColors.purple),
              label: const Text('Ajouter un choix',
                  style: TextStyle(fontSize: 12, color: YekiColors.purple)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _ajouterQuestion,
                icon: const Icon(Icons.save_rounded, size: 16, color: YekiColors.white),
                label: const Text('Enregistrer', style: TextStyle(color: YekiColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.courseColor,
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
            color: sel ? widget.courseColor : YekiColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? widget.courseColor : YekiColors.borderLight, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: sel ? YekiColors.white : YekiColors.textMedium),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? YekiColors.white : YekiColors.textMedium,
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
            color: onTap != null ? col.withValues(alpha: 0.1) : YekiColors.borderLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: onTap != null ? col : YekiColors.textLight),
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: YekiColors.textLight, fontSize: 13),
        filled: true,
        fillColor: YekiColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: YekiColors.borderLight, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: YekiColors.borderLight, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.courseColor, width: 1.5)),
      );
}

// ============================================================
// SHEET GESTION DES SOUMISSIONS (suite à implémenter si besoin)
// ============================================================
class _GestionSoumissionsSheet extends StatefulWidget {
  final DevoirCours devoir;
  final double noteSur;
  final Color courseColor;
  final Future<List<SoumissionItem>> Function() fetchSoumissions;
  final Future<bool> Function(int, double, String) corrigerSoumission;

  const _GestionSoumissionsSheet({
    required this.devoir,
    required this.noteSur,
    required this.courseColor,
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

  List<SoumissionItem> get _corriges => _soumissions.where((s) => s.statut == 'corrige').toList();

  Color _col(String s) {
    switch (s) {
      case 'corrige':
        return YekiColors.success;
      case 'soumis':
        return YekiColors.warning;
      case 'en_retard':
        return YekiColors.error;
      default:
        return YekiColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: YekiColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_alt_outlined, color: YekiColors.purple, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Soumissions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
                          Text(
                            widget.devoir.titre,
                            style: TextStyle(fontSize: 12, color: YekiColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!_loading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: YekiColors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_soumissions.length} soumis',
                          style: const TextStyle(color: YekiColors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  labelColor: widget.courseColor,
                  unselectedLabelColor: YekiColors.textLight,
                  indicatorColor: widget.courseColor,
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
                ? const Center(child: CircularProgressIndicator())
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
      return const Center(child: Text('Aucune soumission', style: TextStyle(color: YekiColors.textLight)));
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
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: col.withValues(alpha: 0.2), width: 1),
            ),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: YekiColors.textDark),
                ),
                if (s.note != null)
                  Text(
                    'Note : ${s.note!.toStringAsFixed(1)} / ${widget.noteSur.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: YekiColors.success, fontWeight: FontWeight.w600),
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
                decoration: BoxDecoration(
                  color: widget.courseColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Corriger',
                    style: TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          if (s.estSuspecte)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: const Icon(Icons.warning_rounded, color: YekiColors.error, size: 18),
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
        backgroundColor: YekiColors.white,
        title: Text('Corriger : ${s.apprenantNom}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (_, setS) => Column(
                children: [
                  Text(
                    '${note.toStringAsFixed(1)} / ${widget.noteSur.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.courseColor),
                  ),
                  Slider(
                    value: note,
                    min: 0,
                    max: widget.noteSur,
                    divisions: (widget.noteSur * 2).toInt(),
                    activeColor: widget.courseColor,
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.courseColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.corrigerSoumission(s.id, note, commentCtrl.text);
              if (ok) _load();
            },
            child: const Text('Valider', style: TextStyle(color: YekiColors.white)),
          ),
        ],
      ),
    );
  }
}