// lib/views/pages/apprenants/resultat_exercice_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE RÉSULTAT EXERCICE — CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

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
        Uri.parse(ApiConstants.resultatExercice(widget.exerciceId)),
        headers: ApiHeaders.auth(token),
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
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: YekiColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: YekiColors.textDark),
        title: Text(widget.exerciceTitre,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: _ouvrirIA,
            icon: const Icon(Icons.psychology_rounded, size: 18),
            label: const Text('Yéki IA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _ouvrirPreoccupation,
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text('Forum', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: YekiLoader())
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
          Icon(Icons.quiz_outlined, size: 70, color: YekiColors.borderLight),
          const SizedBox(height: 16),
          const Text('Aucun résultat disponible',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Faites l\'exercice pour voir votre résultat',
              style: TextStyle(fontSize: 13, color: YekiColors.textLight)),
          const SizedBox(height: 24),
          YekiButton(
            label: 'Retour à l\'exercice',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final note = _toDouble(_data!['note']);
    final noteSur = _toDouble(_data!['note_sur']) != 0 ? _toDouble(_data!['note_sur']) : 20.0;
    final details = _data!['detail'] as List? ?? [];

    double totalPoints = 0;
    double pointsObtenus = 0;

    for (var d in details) {
      final pointsMax = _toDouble(d['points_max']);
      totalPoints += pointsMax;
      if (d['correct'] == true) {
        pointsObtenus += pointsMax;
      }
    }

    final scorePercent = totalPoints > 0 ? (pointsObtenus / totalPoints) : 0.0;
    final bonnes = details.where((d) => d['correct'] == true).length;
    final total = details.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
              borderRadius: YekiRadius.borderRadiusXxl,
            ),
            child: Column(
              children: [
                Icon(scorePercent >= 0.5 ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                    color: YekiColors.white, size: 48),
                const SizedBox(height: 12),
                Text(scorePercent >= 0.5 ? 'Bravo !' : 'Continuez vos efforts !',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 14)),
                const SizedBox(height: 6),
                Text('${pointsObtenus.toStringAsFixed(1)} / ${totalPoints.toStringAsFixed(0)}',
                    style: const TextStyle(color: YekiColors.white, fontSize: 44, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Note : ${note.toStringAsFixed(1)} / ${noteSur.toStringAsFixed(0)}',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$bonnes bonne${bonnes > 1 ? 's' : ''} réponse${bonnes > 1 ? 's' : ''} sur $total',
                    style: TextStyle(color: YekiColors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildIABanner(),
        const SizedBox(height: 12),
        _buildPreoccupationBanner(),
        const SizedBox(height: 24),
        if (details.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _correctionVisible = !_correctionVisible),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: YekiColors.white,
                borderRadius: YekiRadius.borderRadiusLg,
                border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: YekiColors.primaryDark, size: 20),
                  const SizedBox(width: 12),
                  const Text('Voir la correction détaillée',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Icon(_correctionVisible ? Icons.expand_less : Icons.expand_more, color: YekiColors.primaryDark),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_correctionVisible && details.isNotEmpty)
          ...details.asMap().entries.map((e) => _buildDetailQuestion(e.key, e.value)),
        const SizedBox(height: 30),
        YekiButton(
          label: 'Refaire l\'exercice',
          icon: Icons.refresh_rounded,
          onPressed: () => Navigator.pop(context),
          backgroundColor: YekiColors.primaryDark,
        ),
        const SizedBox(height: 20),
      ],
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
        borderRadius: YekiRadius.borderRadiusLg,
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
            decoration: BoxDecoration(color: YekiColors.primaryDark, borderRadius: YekiRadius.borderRadiusSm),
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
          colors: [YekiColors.purple.withValues(alpha: 0.08), YekiColors.purple.withValues(alpha: 0.04)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.purple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: YekiColors.purple.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.help_outline_rounded, color: YekiColors.purple, size: 22),
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
            decoration: BoxDecoration(color: YekiColors.purple, borderRadius: YekiRadius.borderRadiusSm),
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
        borderRadius: YekiRadius.borderRadiusLg,
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
                  borderRadius: YekiRadius.borderRadiusSm,
                ),
                child: Text('${pointsObtenus.toStringAsFixed(0)} / ${pointsMax.toStringAsFixed(0)} pts',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
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
                borderRadius: YekiRadius.borderRadiusSm,
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
          child: Text(valeur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    ),
  );
}