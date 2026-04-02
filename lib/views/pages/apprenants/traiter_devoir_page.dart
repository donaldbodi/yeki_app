import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'devoir_models.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

class TraiterDevoirPage extends StatefulWidget {
  final int    devoirId;
  final String titre;

  const TraiterDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
  });

  @override
  State<TraiterDevoirPage> createState() => _TraiterDevoirPageState();
}

class _TraiterDevoirPageState extends State<TraiterDevoirPage>
    with WidgetsBindingObserver {
  // Couleurs
  static const _cPrimary = Color(0xFF0D1B2A);
  static const _cTeal    = Color(0xFF008088);
  static const _cAccent  = Color(0xFFFF7F77);
  static const _cOlymp   = Color(0xFF7B2FBE);

  bool         _loading    = true;
  bool         _submitting = false;
  DevoirDetail? _devoir;

  // Réponses {question_id: valeur}
  final Map<String, String>          _reponses = {};
  final Map<int, TextEditingController> _ctrls = {};

  // Question par question
  int _idx = 0;

  // Minuteur
  Timer? _timer;
  int    _secsLeft = 0;

  // Anti-triche
  bool _soumis     = false;
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
    // Restaurer UI système si olympiade
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Détection sortie app (anti-triche)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_devoir?.estOlympiade == true && !_soumis && !_forceSubmit) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _signalerSortie();
      }
    }
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    setState(() => _loading = true);
    await _demarrer();
    await _chargerDetail();
    setState(() => _loading = false);
  }

  Future<void> _demarrer() async {
    final token = await _token();
    await http.post(
      Uri.parse('$_baseUrl/devoirs/${widget.devoirId}/demarrer/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );
  }

  Future<void> _chargerDetail() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$_baseUrl/devoirs/${widget.devoirId}/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    if (res.statusCode == 200) {
      final d = DevoirDetail.fromJson(jsonDecode(res.body));
      setState(() => _devoir = d);

      // Minuteur
      if (d.dureeMinutes > 0) {
        _secsLeft = d.tempsRestant ?? (d.dureeMinutes * 60);
        _startTimer();
      }

      // Ctrls texte
      for (final q in d.questions) {
        if (q.type == 'texte') _ctrls[q.id] = TextEditingController();
      }

      // UI immersive olympiade
      if (d.estOlympiade) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secsLeft <= 0) {
        _timer?.cancel();
        if (!_soumis && !_forceSubmit) _soumettreAuto('Temps écoulé');
      } else {
        setState(() => _secsLeft--);
      }
    });
  }

  // ── Anti-triche ────────────────────────────────────────────────────────────
  Future<void> _signalerSortie() async {
    if (_forceSubmit || _soumis) return;
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_baseUrl/devoirs/${widget.devoirId}/focus-perdu/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['force_submit'] == true) {
        _forceSubmit = true;
        _timer?.cancel();
        _snack('Trop de sorties — devoir soumis automatiquement', Colors.red);
        setState(() => _soumis = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        final nb  = data['nb_focus_perdu'] ?? 1;
        final max = (data['max_tolere'] ?? 0) + 1;
        _snack('Sortie $nb/$max détectée !', Colors.orange);
      }
    }
  }

  // ── Soumission ─────────────────────────────────────────────────────────────
  Future<void> _soumettre() async {
    // Sync ctrls texte
    for (final e in _ctrls.entries) {
      _reponses[e.key.toString()] = e.value.text;
    }

    final nb    = _devoir?.questions.length ?? 0;
    final nbRep = _reponses.values.where((v) => v.isNotEmpty).length;

    if (nbRep < nb) {
      final ok = await _confirmer(
        'Questions incomplètes',
        '$nbRep/$nb répondues. Soumettre quand même ?',
      );
      if (!ok) return;
    }

    await _envoyerSoumission();
  }

  Future<void> _soumettreAuto(String raison) async {
    _snack(raison, Colors.orange);
    await _envoyerSoumission();
  }

  Future<void> _envoyerSoumission() async {
    setState(() => _submitting = true);
    final token = await _token();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/devoirs/${widget.devoirId}/soumettre/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({'reponses': _reponses}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _timer?.cancel();
        setState(() { _soumis = true; _submitting = false; });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _snack('Devoir soumis avec succès !', _cTeal);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        final body = jsonDecode(res.body);
        _snack(body['detail'] ?? 'Erreur lors de la soumission.', Colors.red);
      }
    } catch (_) {
      _snack('Erreur réseau.', Colors.red);
    }
    setState(() => _submitting = false);
  }

  Future<bool> _confirmer(String titre, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(titre),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: _cAccent),
                child: const Text('Soumettre',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF008088)),
              SizedBox(height: 16),
              Text('Chargement du devoir...', style: TextStyle(
                  color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final d = _devoir!;

    return WillPopScope(
      onWillPop: () async {
        if (d.estOlympiade && !_soumis) {
          final ok = await _confirmer(
            'Quitter l\'olympiade ?',
            'Une sortie sera comptabilisée. Continuer ?',
          );
          if (ok) _signalerSortie();
          return false;
        }
        if (!_soumis) {
          return await _confirmer(
            'Quitter ?',
            'Votre progression sera sauvegardée. Quitter maintenant ?',
          );
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(children: [
          _buildTopBar(d),
          Expanded(
            child: d.questionParQuestion
                ? _buildModeQParQ(d)
                : _buildModeTout(d),
          ),
          if (!d.questionParQuestion) _buildBottomBar(),
        ]),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(DevoirDetail d) {
    final isOlymp  = d.estOlympiade;
    final topColor = isOlymp ? _cOlymp : _cPrimary;
    final progress = d.questions.isEmpty ? 0.0
        : _reponses.values.where((v) => v.isNotEmpty).length / d.questions.length;

    return Container(
      decoration: BoxDecoration(
        color: topColor,
        boxShadow: [BoxShadow(
            color: topColor.withOpacity(0.3), blurRadius: 10)],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              // Retour (sauf olympiade)
              if (!isOlymp)
                GestureDetector(
                  onTap: () async {
                    final ok = await _confirmer('Quitter ?',
                        'Progression sauvegardée. Quitter maintenant ?');
                    if (ok && mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              if (!isOlymp) const SizedBox(width: 12),
              Expanded(
                child: Text(d.titre, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 15,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (d.dureeMinutes > 0) ...[
                const SizedBox(width: 12),
                _minuteur(),
              ],
            ]),
          ),
          // Barre progression
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isOlymp ? const Color(0xFFE2A84B) : _cAccent),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_reponses.values.where((v) => v.isNotEmpty).length}/${_devoir!.questions.length}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _minuteur() {
    final mins   = _secsLeft ~/ 60;
    final secs   = _secsLeft % 60;
    final urgent = _secsLeft <= 120;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? _cAccent : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(urgent ? Icons.warning_rounded : Icons.timer_rounded,
            color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Text(
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }

  // ── Mode question par question ──────────────────────────────────────────────
  Widget _buildModeQParQ(DevoirDetail d) {
    if (d.questions.isEmpty) return const Center(child: Text('Aucune question.'));
    final q = d.questions[_idx];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Text('Question ${_idx + 1} / ${d.questions.length}',
              style: TextStyle(color: Colors.grey.shade500,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${q.points} pt${q.points > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: Color(0xFF008088), fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      // Indicateurs
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(children: List.generate(d.questions.length, (i) {
          final rep = _reponses[d.questions[i].id.toString()] ?? '';
          return Expanded(
            child: Container(
              height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == _idx
                    ? const Color(0xFF008088)
                    : rep.isNotEmpty
                        ? const Color(0xFFE2A84B)
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        })),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildQuestion(q),
        ),
      ),
      // Navigation
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Row(children: [
          // Précédent (si pas olympiade question_par_question strict)
          if (_idx > 0 && !d.questionParQuestion) ...[
            Expanded(
              child: _btn('Précédent', Colors.grey.shade200,
                  Colors.grey.shade700,
                  () => setState(() => _idx--)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _idx < d.questions.length - 1
                ? _btn('Question suivante', const Color(0xFF008088),
                    Colors.white, () => setState(() => _idx++))
                : _btn('Soumettre le devoir', _cAccent, Colors.white,
                    _submitting ? null : _soumettre),
          ),
        ]),
      ),
    ]);
  }

  // ── Mode toutes questions ───────────────────────────────────────────────────
  Widget _buildModeTout(DevoirDetail d) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: d.questions.length,
      itemBuilder: (_, i) => _buildQuestion(d.questions[i]),
    );
  }

  // ── Question ────────────────────────────────────────────────────────────────
  Widget _buildQuestion(QuestionDevoir q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${q.points} pt${q.points > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF008088),
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(q.type == 'qcm' ? 'QCM' : 'Réponse libre',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(q.texte, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: Color(0xFF0D1B2A), height: 1.5,
        )),
        const SizedBox(height: 14),
        if (q.type == 'qcm') _buildQCM(q) else _buildTexteLibre(q),
      ]),
    );
  }

  Widget _buildQCM(QuestionDevoir q) {
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
              color: isSel ? const Color(0xFFE0F4F4) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? const Color(0xFF008088) : Colors.grey.shade200,
                width: isSel ? 2 : 1,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF008088)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel
                        ? const Color(0xFF008088)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSel
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(c.texte, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: isSel
                    ? const Color(0xFF0D1B2A)
                    : Colors.grey.shade700,
              ))),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTexteLibre(QuestionDevoir q) {
    _ctrls.putIfAbsent(q.id, () => TextEditingController());
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _ctrls[q.id],
        maxLines: 5,
        onChanged: (v) => _reponses[q.id.toString()] = v,
        decoration: InputDecoration(
          hintText: 'Rédigez votre réponse ici...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── Bottom bar (mode tout) ──────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: _submitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008088)))
          : _btn('Soumettre le devoir', _cAccent, Colors.white, _soumettre),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bg : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [BoxShadow(color: bg.withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(
              color: onTap != null ? fg : Colors.grey.shade400,
              fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}
