import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseC = 'https://yekiapp.pythonanywhere.com/api';

// ─── Palette ──────────────────────────────────────────────────
const Color _teal   = Color(0xFF008088);
const Color _dark   = Color(0xFF1A1C1E);
const Color _accent = Color(0xFFFF7F77);
const Color _gold   = Color(0xFFE2A84B);
const Color _bg     = Color(0xFFF5F7FA);

// ─── Modèles locaux ───────────────────────────────────────────
class _Choix {
  final int    id;
  final String texte;
  const _Choix({required this.id, required this.texte});
  factory _Choix.fromJson(Map j) =>
      _Choix(id: j['id'], texte: j['texte'] ?? '');
}

class _Question {
  final int         id;
  final String      texte;
  final String      type; // qcm | texte
  final int         points;
  final int         ordre;
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
    id:     j['id'],
    texte:  j['texte'] ?? '',
    type:   j['type_question'] ?? 'texte',
    points: j['points'] ?? 1,
    ordre:  j['ordre'] ?? 0,
    choix:  (j['choix'] as List? ?? [])
                .map((c) => _Choix.fromJson(c))
                .toList(),
  );
}

// ═════════════════════════════════════════════════════════════
class ComposerDevoirPage extends StatefulWidget {
  final int    devoirId;
  final String titre;
  final int    dureeMin;
  final int    noteSur;

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

  bool              _loading    = true;
  bool              _submitting = false;
  List<_Question>   _questions  = [];
  bool              _qParQ      = false;
  bool              _estOlymp   = false;
  int               _nbSortiesMax = 0;

  // Réponses {question_id: valeur}
  final Map<String, String>             _reponses = {};
  final Map<int, TextEditingController> _ctrls    = {};

  // Navigation Q par Q
  int _idx = 0;

  // Minuteur
  Timer? _timer;
  int    _secsLeft = 0;
  bool   _soumis   = false;

  // Anti-triche
  int  _nbSorties   = 0;
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

  // ── Init ──────────────────────────────────────────────────
  Future<void> _init() async {
    setState(() => _loading = true);
    await _demarrer();
    await _chargerDetail();
    setState(() => _loading = false);
  }

  Future<void> _demarrer() async {
    final token = await _token();
    await http.post(
      Uri.parse('$_baseC/devoirs/${widget.devoirId}/demarrer/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );
  }

  Future<void> _chargerDetail() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('$_baseC/devoirs/${widget.devoirId}/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final olymp = data['olympiade'] as Map<String, dynamic>?;
      _estOlymp       = (data['type_devoir'] ?? '') == 'olympiade';
      _qParQ          = olymp?['question_par_question'] == true;
      _nbSortiesMax   = olymp?['nb_sorties_tolerees'] ?? 0;

      _questions = (data['questions'] as List? ?? [])
          .map((q) => _Question.fromJson(q))
          .toList();

      // Controllers texte
      for (final q in _questions) {
        if (q.type == 'texte') _ctrls[q.id] = TextEditingController();
      }

      // Minuteur (priorité : temps_restant du backend, sinon duree_minutes)
      final tr = data['temps_restant'] as int?;
      if (widget.dureeMin > 0) {
        _secsLeft = tr ?? (widget.dureeMin * 60);
        _startTimer();
      }

      // UI immersive olympiade
      if (_estOlymp) {
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

  // ── Anti-triche ──────────────────────────────────────────
  Future<void> _signalerSortie() async {
    if (_forceSubmit || _soumis) return;
    _nbSorties++;
    final token = await _token();
    final res = await http.post(
      Uri.parse('$_baseC/devoirs/${widget.devoirId}/sortie/'),
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
        final nb  = data['nb_sorties'] ?? _nbSorties;
        final max = (_nbSortiesMax) + 1;
        _snack('Sortie $nb/$max détectée !', Colors.orange);
      }
    }
  }

  // ── Soumission ────────────────────────────────────────────
  Future<void> _soumettre() async {
    // Synchroniser texte libre
    for (final e in _ctrls.entries) {
      _reponses[e.key.toString()] = e.value.text;
    }

    final nb    = _questions.length;
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
    for (final e in _ctrls.entries) {
      _reponses[e.key.toString()] = e.value.text;
    }
    _snack(raison, Colors.orange);
    await _envoyerSoumission();
  }

  Future<void> _envoyerSoumission() async {
    setState(() => _submitting = true);
    final token = await _token();
    try {
      final res = await http.post(
        Uri.parse('$_baseC/devoirs/${widget.devoirId}/soumettre/'),
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
        _snack('Devoir soumis avec succès !', _teal);
        await Future.delayed(const Duration(milliseconds: 700));
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(titre,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmer',
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _teal),
              SizedBox(height: 16),
              Text('Chargement du devoir…',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_estOlymp && !_soumis) {
          final ok = await _confirmer(
            'Quitter l\'olympiade ?',
            'Une sortie sera comptabilisée. Continuer ?',
          );
          if (ok) _signalerSortie();
          return false;
        }
        if (!_soumis) {
          return _confirmer('Quitter ?',
              'Ta progression est sauvegardée. Quitter maintenant ?');
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(children: [
          _buildTopBar(),
          Expanded(
            child: _qParQ
                ? _buildModeQParQ()
                : _buildModeTout(),
          ),
          if (!_qParQ) _buildBottomBar(),
        ]),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar() {
    final topColor = _estOlymp ? const Color(0xFF7B2FBE) : _dark;
    final progress = _questions.isEmpty
        ? 0.0
        : _reponses.values.where((v) => v.isNotEmpty).length /
              _questions.length;

    return Container(
      decoration: BoxDecoration(
        color: topColor,
        boxShadow: [
          BoxShadow(
              color: topColor.withOpacity(0.3), blurRadius: 10)
        ],
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
                    final ok = await _confirmer(
                        'Quitter ?', 'Progression sauvegardée. Quitter ?');
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
              if (!_estOlymp) const SizedBox(width: 12),
              Expanded(
                child: Text(widget.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
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
                        _estOlymp ? _gold : _accent),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_reponses.values.where((v) => v.isNotEmpty).length}/${_questions.length}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent
            ? _accent
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          urgent
              ? Icons.warning_rounded
              : Icons.timer_rounded,
          color: Colors.white,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }

  // ── Mode Q par Q ──────────────────────────────────────────
  Widget _buildModeQParQ() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Aucune question.'));
    }
    final q = _questions[_idx];

    return Column(children: [
      // Header question
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Text(
            'Question ${_idx + 1} / ${_questions.length}',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text('${q.points} pt${q.points > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: _teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      // Indicateurs mini
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: List.generate(_questions.length, (i) {
            final rep =
                _reponses[_questions[i].id.toString()] ?? '';
            return Expanded(
              child: Container(
                height: 4,
                margin:
                    const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i == _idx
                      ? _teal
                      : rep.isNotEmpty
                          ? _gold
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
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
      // Navigation
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Row(children: [
          // Précédent (si pas strict olympiade)
          if (_idx > 0 && !_estOlymp) ...[
            Expanded(
              child: _btn(
                'Précédent',
                Colors.grey.shade200,
                Colors.grey.shade700,
                () => setState(() => _idx--),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _idx < _questions.length - 1
                ? _btn('Question suivante', _teal, Colors.white,
                    () => setState(() => _idx++))
                : _btn(
                    'Soumettre',
                    _accent,
                    Colors.white,
                    _submitting ? null : _soumettre,
                  ),
          ),
        ]),
      ),
    ]);
  }

  // ── Mode tout ─────────────────────────────────────────────
  Widget _buildModeTout() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: _questions.length,
      itemBuilder: (_, i) => _buildQuestion(_questions[i]),
    );
  }

  // ── Question ──────────────────────────────────────────────
  Widget _buildQuestion(_Question q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${q.points} pt${q.points > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 10,
                    color: _teal,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              q.type == 'qcm' ? 'QCM' : 'Réponse libre',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            q.texte,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _dark,
              height: 1.5,
            ),
          ),
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
          onTap: () =>
              setState(() => _reponses[q.id.toString()] = c.texte),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isSel ? const Color(0xFFE0F4F4) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? _teal : Colors.grey.shade200,
                width: isSel ? 2 : 1,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSel ? _teal : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSel ? _teal : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSel
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.texte,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSel ? _dark : Colors.grey.shade700,
                  ),
                ),
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _ctrls[q.id],
        maxLines: 5,
        onChanged: (v) => _reponses[q.id.toString()] = v,
        decoration: InputDecoration(
          hintText: 'Rédigez votre réponse ici…',
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── Bottom bar (mode tout) ────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: _submitting
          ? const Center(
              child: CircularProgressIndicator(color: _teal))
          : _btn('Soumettre le devoir', _accent, Colors.white,
              _soumettre),
    );
  }

  Widget _btn(
      String label, Color bg, Color fg, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bg : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                      color: bg.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onTap != null ? fg : Colors.grey.shade400,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
