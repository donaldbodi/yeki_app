// lib/views/pages/apprenants/composer_devoir_page.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class _Choix {
  final int id;
  final String texte;
  const _Choix({required this.id, required this.texte});
  factory _Choix.fromJson(Map j) => _Choix(id: j['id'], texte: j['texte'] ?? '');
}

class _Question {
  final int id;
  final String texte;
  final String type;
  final int points;
  final int ordre;
  final List<_Choix> choix;
  const _Question({
    required this.id,
    required this.texte,
    required this.type,
    required this.points,
    required this.ordre,
    required this.choix,
  });
  factory _Question.fromJson(Map j) => _Question(
    id: j['id'],
    texte: j['texte'] ?? '',
    type: j['type_question'] ?? 'texte',
    points: j['points'] ?? 1,
    ordre: j['ordre'] ?? 0,
    choix: (j['choix'] as List? ?? []).map((c) => _Choix.fromJson(c)).toList(),
  );
}

class ComposerDevoirPage extends StatefulWidget {
  final int devoirId;
  final String titre;
  final int dureeMin;
  final int noteSur;

  const ComposerDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
    required this.dureeMin,
    required this.noteSur,
  });

  @override
  State<ComposerDevoirPage> createState() => _ComposerDevoirPageState();
}

class _ComposerDevoirPageState extends State<ComposerDevoirPage>
    with WidgetsBindingObserver {

  bool _loading = true;
  bool _submitting = false;
  List<_Question> _questions = [];
  bool _qParQ = false;
  bool _estOlymp = false;
  int _nbSortiesMax = 0;

  final Map<String, String> _reponses = {};
  final Map<int, TextEditingController> _ctrls = {};

  int _idx = 0;
  Timer? _timer;
  int _secsLeft = 0;
  bool _soumis = false;
  int _nbSorties = 0;
  bool _forceSubmit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final c in _ctrls.values) c.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_estOlymp && !_soumis && !_forceSubmit) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _signalerSortie();
      }
    }
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _demarrer();
    await _chargerDetail();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _demarrer() async {
    final token = await _token();
    await http.post(
      Uri.parse(ApiConstants.devoirDemarrer(widget.devoirId)),
      headers: ApiHeaders.auth(token),
    );
  }

  Future<void> _chargerDetail() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(ApiConstants.devoirDetail(widget.devoirId)),
      headers: ApiHeaders.auth(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final olymp = data['olympiade'] as Map<String, dynamic>?;
      _estOlymp = (data['type_devoir'] ?? '') == 'olympiade';
      _qParQ = olymp?['question_par_question'] == true;
      _nbSortiesMax = olymp?['nb_sorties_tolerees'] ?? 0;

      _questions = (data['questions'] as List? ?? [])
          .map((q) => _Question.fromJson(q))
          .toList();

      for (final q in _questions) {
        if (q.type == 'texte') _ctrls[q.id] = TextEditingController();
      }

      final tr = data['temps_restant'] as int?;
      if (widget.dureeMin > 0) {
        _secsLeft = tr ?? (widget.dureeMin * 60);
        _startTimer();
      }

      if (_estOlymp) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secsLeft <= 0) {
        _timer?.cancel();
        if (!_soumis && !_forceSubmit) _soumettreAuto('Temps écoulé');
      } else {
        setState(() => _secsLeft--);
      }
    });
  }

  Future<void> _signalerSortie() async {
    if (_forceSubmit || _soumis) return;
    _nbSorties++;
    final token = await _token();
    final res = await http.post(
      Uri.parse(ApiConstants.devoirFocusPerdu(widget.devoirId)),
      headers: ApiHeaders.auth(token),
    );
    if (res.statusCode == 200 && mounted) {
      final data = jsonDecode(res.body);
      if (data['force_submit'] == true) {
        _forceSubmit = true;
        _timer?.cancel();
        if (mounted) ErrorHandler.showWarning(context, 'Trop de sorties — devoir soumis automatiquement');
        setState(() => _soumis = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        final nb = data['nb_focus_perdu'] ?? _nbSorties;
        final max = (_nbSortiesMax) + 1;
        if (mounted) ErrorHandler.showWarning(context, 'Sortie $nb/$max détectée !');
      }
    }
  }

  Future<void> _soumettre() async {
    for (final e in _ctrls.entries) {
      _reponses[e.key.toString()] = e.value.text;
    }

    final nb = _questions.length;
    final nbRep = _reponses.values.where((v) => v.isNotEmpty).length;

    if (nbRep < nb) {
      final ok = await _confirmer('Questions incomplètes', '$nbRep/$nb répondues. Soumettre quand même ?');
      if (ok != true) return;
    }
    await _envoyerSoumission();
  }

  Future<void> _soumettreAuto(String raison) async {
    for (final e in _ctrls.entries) {
      _reponses[e.key.toString()] = e.value.text;
    }
    if (mounted) ErrorHandler.showWarning(context, raison);
    await _envoyerSoumission();
  }

  Future<void> _envoyerSoumission() async {
    setState(() => _submitting = true);
    final token = await _token();
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.devoirSoumettre(widget.devoirId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'reponses': _reponses}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _timer?.cancel();
        if (mounted) {
          setState(() { _soumis = true; _submitting = false; });
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          ErrorHandler.showSuccess(context, 'Devoir soumis avec succès !');
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) Navigator.pop(context, true);
        }
      } else {
        final body = jsonDecode(res.body);
        if (mounted) ErrorHandler.showError(context, body['detail'] ?? 'Erreur lors de la soumission.');
      }
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau.');
    }
    if (mounted) setState(() => _submitting = false);
  }

  Future<bool?> _confirmer(String titre, String msg) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusXl),
        backgroundColor: YekiColors.white,
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.accent,
              shape: RoundedRectangleBorder(borderRadius: YekiRadius.borderRadiusMd),
            ),
            child: const Text('Confirmer', style: TextStyle(color: YekiColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YekiLoader(),
              SizedBox(height: 16),
              Text('Chargement du devoir…',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && mounted) {
          if (_estOlymp && !_soumis) {
            final ok = await _confirmer('Quitter l\'olympiade ?', 'Une sortie sera comptabilisée. Continuer ?');
            if (ok == true) _signalerSortie();
            if (ok == true && mounted) Navigator.pop(context);
          } else if (!_soumis) {
            final ok = await _confirmer('Quitter ?', 'Ta progression est sauvegardée. Quitter maintenant ?');
            if (ok == true && mounted) Navigator.pop(context);
          } else {
            if (mounted) Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: Column(children: [
          _buildTopBar(),
          Expanded(
            child: _qParQ ? _buildModeQParQ() : _buildModeTout(),
          ),
          if (!_qParQ) _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    final topColor = _estOlymp ? YekiColors.purple : YekiColors.textDark;
    final progress = _questions.isEmpty
        ? 0.0
        : _reponses.values.where((v) => v.isNotEmpty).length / _questions.length;

    return Container(
      decoration: BoxDecoration(
        color: topColor,
        boxShadow: [BoxShadow(color: topColor.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              if (!_estOlymp)
                GestureDetector(
                  onTap: () async {
                    final ok = await _confirmer('Quitter ?', 'Progression sauvegardée. Quitter ?');
                    if (ok == true && mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: YekiColors.white.withValues(alpha: 0.15),
                      borderRadius: YekiRadius.borderRadiusSm,
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  ),
                ),
              if (!_estOlymp) const SizedBox(width: 12),
              Expanded(
                child: Text(widget.titre,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.dureeMin > 0) ...[
                const SizedBox(width: 12),
                _minuteur(),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: YekiRadius.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: YekiColors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_estOlymp ? YekiColors.accent : YekiColors.accent),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_reponses.values.where((v) => v.isNotEmpty).length}/${_questions.length}',
                style: TextStyle(color: YekiColors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _minuteur() {
    final mins = _secsLeft ~/ 60;
    final secs = _secsLeft % 60;
    final urgent = _secsLeft <= 120;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? YekiColors.accent : YekiColors.white.withValues(alpha: 0.15),
        borderRadius: YekiRadius.borderRadiusXl,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(urgent ? Icons.warning_rounded : Icons.timer_rounded, size: 14),
        const SizedBox(width: 5),
        Text(
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ]),
    );
  }

  Widget _buildModeQParQ() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Aucune question.'));
    }
    final q = _questions[_idx];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Text('Question ${_idx + 1} / ${_questions.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${q.points} pt${q.points > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: List.generate(_questions.length, (i) {
            final rep = _reponses[_questions[i].id.toString()] ?? '';
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == _idx ? YekiColors.primaryDark : (rep.isNotEmpty ? YekiColors.accent : YekiColors.borderLight),
                  borderRadius: YekiRadius.borderRadiusSm,
                ),
              ),
            );
          }),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildQuestion(q),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Row(children: [
          if (_idx > 0 && !_estOlymp) ...[
            Expanded(
              child: _btn('Précédent', YekiColors.borderLight, YekiColors.textDark, () => setState(() => _idx--)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _idx < _questions.length - 1
                ? _btn('Question suivante', YekiColors.primaryDark, YekiColors.white, () => setState(() => _idx++))
                : _btn('Soumettre', YekiColors.accent, YekiColors.white, _submitting ? null : _soumettre),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildModeTout() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: _questions.length,
      itemBuilder: (_, i) => _buildQuestion(_questions[i]),
    );
  }

  Widget _buildQuestion(_Question q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        boxShadow: YekiShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4F4),
                borderRadius: YekiRadius.borderRadiusSm,
              ),
              child: Text('${q.points} pt${q.points > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(q.type == 'qcm' ? 'QCM' : 'Réponse libre',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Text(q.texte, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.5)),
          const SizedBox(height: 14),
          if (q.type == 'qcm')
            _buildQCM(q)
          else
            _buildTexteLibre(q),
        ],
      ),
    );
  }

  Widget _buildQCM(_Question q) {
    final sel = _reponses[q.id.toString()];
    return Column(
      children: q.choix.map((c) {
        final isSel = sel == c.texte;
        return GestureDetector(
          onTap: () => setState(() => _reponses[q.id.toString()] = c.texte),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFFE0F4F4) : YekiColors.backgroundLight,
              borderRadius: YekiRadius.borderRadiusMd,
              border: Border.all(color: isSel ? YekiColors.primaryDark : YekiColors.borderLight, width: isSel ? 2 : 1),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isSel ? YekiColors.primaryDark : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSel ? YekiColors.primaryDark : YekiColors.borderLight, width: 2),
                ),
                child: isSel ? const Icon(Icons.check_rounded, size: 13) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.texte,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSel ? YekiColors.textDark : YekiColors.textMedium)),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTexteLibre(_Question q) {
    _ctrls.putIfAbsent(q.id, () => TextEditingController());
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.backgroundLight,
        borderRadius: YekiRadius.borderRadiusMd,
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: TextField(
        controller: _ctrls[q.id],
        maxLines: 5,
        onChanged: (v) => _reponses[q.id.toString()] = v,
        decoration: const InputDecoration(
          hintText: 'Rédigez votre réponse ici…',
          hintStyle: TextStyle(fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: YekiColors.white,
        boxShadow: YekiShadows.subtle,
      ),
      child: _submitting
          ? const Center(child: YekiLoader())
          : _btn('Soumettre le devoir', YekiColors.accent, YekiColors.white, _soumettre),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bg : YekiColors.borderLight,
          borderRadius: YekiRadius.borderRadiusLg,
          boxShadow: onTap != null ? [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: onTap != null ? fg : YekiColors.textLight, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}