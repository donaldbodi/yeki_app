import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/form_question_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// MODÈLE LECON (dynamique depuis API)
// ─────────────────────────────────────────────────────────────────
class Lecon {
  final int    id;
  final String titre;
  final String duree;
  final String description;
  final bool   hasPdf;
  final bool   estTerminee;
  final String videoUrl;
  final String pdfUrl;
  final int    numero;

  const Lecon({
    required this.id,
    required this.titre,
    required this.duree,
    required this.description,
    this.hasPdf      = false,
    this.estTerminee = false,
    this.videoUrl    = '',
    this.pdfUrl      = '',
    required this.numero,
  });

  factory Lecon.fromJson(Map<String, dynamic> j, {int numero = 1}) => Lecon(
    id:          j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
    titre:       j['titre'] ?? '',
    duree:       j['duree'] ?? '',
    description: j['description'] ?? '',
    hasPdf:      j['pdf_url'] != null && j['pdf_url'].toString().isNotEmpty,
    estTerminee: j['est_terminee'] ?? false,
    videoUrl:    j['video_url'] ?? '',
    pdfUrl:      j['pdf_url'] ?? '',
    numero:      j['ordre'] ?? numero,
  );
}

// ─────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────
const String _base = 'https://yekiapp.pythonanywhere.com/api';

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ─────────────────────────────────────────────────────────────────
// PAGE LECTURE LECON — dynamique
// ─────────────────────────────────────────────────────────────────
class LectureLeconPage extends StatefulWidget {
  final int    leconId;          // ID de la leçon initiale
  final int    coursId;          // Pour charger toutes les leçons du cours
  final String coursTitre;       // Pour l'affichage et le contexte forum

  const LectureLeconPage({
    super.key,
    required this.leconId,
    required this.coursId,
    required this.coursTitre,
  });

  @override
  State<LectureLeconPage> createState() => _LectureLeconPageState();
}

class _LectureLeconPageState extends State<LectureLeconPage>
    with TickerProviderStateMixin {
  // ── Couleurs ──────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0D1B2A);
  static const Color _teal    = Color(0xFF008088);
  static const Color _accent  = Color(0xFFFF7F77);
  //static const Color _gold    = Color(0xFFE2A84B);
  static const Color _bg      = Color(0xFFF5F7FA);

  // ── State ─────────────────────────────────────────────────────
  bool         _loading     = true;
  Lecon?       _leconCourante;
  List<Lecon>  _toutesLecons = [];
  double       _progression  = 0.0;

  bool   _isFullscreen    = false;
  bool   _isVideoPlaying  = false;
  bool   _showControls    = true;
  bool   _isLiked         = false;
  bool   _marquageLoading = false;

  late AnimationController _controlsCtrl;
  late AnimationController _fabCtrl;
  late Animation<double>   _controlsAnim;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _controlsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _controlsAnim = CurvedAnimation(
        parent: _controlsCtrl, curve: Curves.easeOut);
    _controlsCtrl.value = 1.0;
    _fabCtrl.forward();
    _charger();
  }

  @override
  void dispose() {
    _controlsCtrl.dispose();
    _fabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Chargement ────────────────────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    try {
      // Charger toutes les leçons du cours
      final res = await http.get(
        Uri.parse('$_base/cours/${widget.coursId}/liste-modules/'),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final modules = jsonDecode(res.body) as List;
        final List<Lecon> toutes = [];
        int numero = 1;
        for (final module in modules) {
          final lecons = module['lecons'] as List? ?? [];
          for (final l in lecons) {
            toutes.add(Lecon.fromJson(l, numero: numero++));
          }
        }

        // Leçon courante
        Lecon? courante = toutes.firstWhere(
          (l) => l.id == widget.leconId,
          orElse: () => toutes.isNotEmpty ? toutes.first : Lecon(
            id: widget.leconId, titre: '', duree: '', description: '',
            numero: 1,
          ),
        );

        // Calcul progression
        final terminees = toutes.where((l) => l.estTerminee).length;
        final prog = toutes.isEmpty ? 0.0 : terminees / toutes.length;

        setState(() {
          _toutesLecons  = toutes;
          _leconCourante = courante;
          _progression   = prog;
          _loading       = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Marquer leçon comme terminée ──────────────────────────────
  Future<void> _marquerTerminee() async {
    final lecon = _leconCourante;
    if (lecon == null || lecon.estTerminee) return;

    setState(() => _marquageLoading = true);
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('$_base/lecons/${lecon.id}/terminer/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _charger(); // Recharger pour mettre à jour la progression
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Leçon marquée comme terminée ✓'),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _marquageLoading = false);
  }

  // ── Changer leçon ─────────────────────────────────────────────
  void _changerLecon(Lecon lecon) {
    setState(() {
      _leconCourante = lecon;
      _isVideoPlaying = false;
      _showControls = true;
      _controlsCtrl.value = 1.0;
    });
    _scrollCtrl.animateTo(
        0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _controlsCtrl.forward();
    else _controlsCtrl.reverse();
  }

  // ── Ouvrir formulaire de question forum ───────────────────────
  void _ouvrirQuestionForum() {
    final lecon = _leconCourante;
    if (lecon == null) return;
    ouvrirQuestionForum(
      context,
      source:      'lecon',
      leconId:     lecon.id,
      leconTitre:  lecon.titre,
      coursId:     widget.coursId,
      coursTitre:  widget.coursTitre,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF008088))));
    }

    final lecon = _leconCourante;
    if (lecon == null) {
      return const Scaffold(body: Center(child: Text('Leçon introuvable')));
    }

    if (_isFullscreen) return _buildFullscreenVideo(lecon);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(children: [
            _buildVideoZone(lecon),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeconHeader(lecon),
                    _buildActionsRapides(lecon),
                    _buildDescription(lecon),
                    _buildListeLecons(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ]),
          // FAB — Poser une question forum
          _buildFabQuestion(),
        ],
      ),
    );
  }

  // ── Zone vidéo ───────────────────────────────────────────────
  Widget _buildVideoZone(Lecon lecon) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity, height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF00404A), Color(0xFF0D1B2A)],
          ),
        ),
        child: Stack(children: [
          Center(
            child: AnimatedBuilder(
              animation: _controlsAnim,
              builder: (_, __) => Opacity(
                opacity: _controlsAnim.value,
                child: GestureDetector(
                  onTap: () => setState(() => _isVideoPlaying = !_isVideoPlaying),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _isVideoPlaying
                          ? Colors.white.withOpacity(0.15) : _accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: _accent.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: Icon(
                      _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0,
              child: _buildVideoTopBar(lecon)),
          Positioned(bottom: 0, left: 0, right: 0,
              child: _buildVideoBottomBar()),
        ]),
      ),
    );
  }

  Widget _buildVideoTopBar(Lecon lecon) => AnimatedBuilder(
    animation: _controlsAnim,
    builder: (_, __) => Opacity(
      opacity: _controlsAnim.value,
      child: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16, bottom: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent]),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(lecon.titre,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20)),
            child: Text('Leçon ${lecon.numero}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ),
  );

  Widget _buildVideoBottomBar() => AnimatedBuilder(
    animation: _controlsAnim,
    builder: (_, __) => Opacity(
      opacity: _controlsAnim.value,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent]),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: _accent,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(value: 0.35, onChanged: (_) {}),
          ),
          Row(children: [
            const Text('6:18', style: TextStyle(color: Colors.white70, fontSize: 11)),
            const Spacer(),
            const Text('18:00', style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _toggleFullscreen,
              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
            ),
          ]),
        ]),
      ),
    ),
  );

  Widget _buildFullscreenVideo(Lecon lecon) => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: _toggleControls,
      child: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF00404A), Color(0xFF0D1B2A)])),
        ),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isVideoPlaying = !_isVideoPlaying),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _accent, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.5), blurRadius: 30)]),
              child: Icon(
                _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controlsAnim,
          builder: (_, __) => Opacity(
            opacity: _controlsAnim.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xCC000000), Colors.transparent])),
                  child: Row(children: [
                    GestureDetector(
                      onTap: _toggleFullscreen,
                      child: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 26)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(lecon.titre,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent])),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        activeTrackColor: _accent, inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white),
                      child: Slider(value: 0.35, onChanged: (_) {}),
                    ),
                    Row(children: [
                      const Text('6:18', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      const Text('18:00', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ]),
    ),
  );

  // ── Header leçon ─────────────────────────────────────────────
  Widget _buildLeconHeader(Lecon lecon) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Text('${lecon.numero}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lecon.titre,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _primary)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.schedule_outlined, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(lecon.duree, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(width: 12),
              if (lecon.estTerminee)
                Row(children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text('Terminée',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600,
                          fontWeight: FontWeight.w600)),
                ]),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => _isLiked = !_isLiked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isLiked ? const Color(0xFFFFEEEE) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
            child: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? Colors.redAccent : Colors.grey.shade400, size: 18),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      // Progression du cours
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Progression du cours',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${(_progression * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progression,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(_teal),
            minHeight: 6,
          ),
        ),
      ]),
    ]),
  );

  // ── Actions rapides ──────────────────────────────────────────
  Widget _buildActionsRapides(Lecon lecon) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Divider(color: Colors.grey.shade100, height: 1),
      const SizedBox(height: 16),
      Text('Actions',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 12),
      Row(children: [
        _actionBtn(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Lire PDF',
          color: const Color(0xFFE53935),
          enabled: lecon.hasPdf,
          onTap: () { /* Ouvrir PDF */ },
        ),
        const SizedBox(width: 10),
        _actionBtn(
          icon: Icons.help_outline_rounded,
          label: 'Question',
          color: const Color(0xFF1565C0),  // Bleu "leçon"
          enabled: true,
          onTap: _ouvrirQuestionForum,     // ← INTÉGRATION FORUM
        ),
        const SizedBox(width: 10),
        _actionBtn(
          icon: Icons.check_circle_outline_rounded,
          label: 'Marquer fait',
          color: Colors.green.shade600,
          enabled: !lecon.estTerminee,
          onTap: _marquerTerminee,
          loading: _marquageLoading,
        ),
        const SizedBox(width: 10),
        _actionBtn(
          icon: Icons.share_rounded,
          label: 'Partager',
          color: _teal,
          enabled: true,
          onTap: () {},
        ),
      ]),
    ]),
  );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
  }) => Expanded(
    child: GestureDetector(
      onTap: enabled && !loading ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF5FAFA) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: enabled ? const Color(0xFFDDF0F0) : Colors.grey.shade200)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            loading
                ? SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: enabled ? color : Colors.grey.shade400, size: 22),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: enabled ? color : Colors.grey.shade400)),
          ]),
        ),
      ),
    ),
  );

  // ── Description ──────────────────────────────────────────────
  Widget _buildDescription(Lecon lecon) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: _teal),
        const SizedBox(width: 8),
        const Text('À propos de cette leçon',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primary)),
      ]),
      const SizedBox(height: 10),
      Text(lecon.description,
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600, height: 1.6)),
    ]),
  );

  // ── Liste des leçons ─────────────────────────────────────────
  Widget _buildListeLecons() {
    if (_toutesLecons.isEmpty) return const SizedBox.shrink();
    final lecon = _leconCourante;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Icon(Icons.playlist_play_rounded, size: 18, color: _teal),
            const SizedBox(width: 8),
            const Text('Toutes les leçons',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFE0F4F4), borderRadius: BorderRadius.circular(20)),
              child: Text('${_toutesLecons.length} leçons',
                  style: const TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        ..._toutesLecons.map((l) => _buildLeconTile(l, lecon)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildLeconTile(Lecon lecon, Lecon? courante) {
    final isCurrent = courante != null && lecon.id == courante.id;
    return GestureDetector(
      onTap: () => _changerLecon(lecon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFE0F4F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCurrent ? _teal : Colors.transparent)),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: isCurrent ? _teal
                  : lecon.estTerminee ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: lecon.estTerminee && !isCurrent
                  ? Icon(Icons.check_rounded, color: Colors.green.shade600, size: 16)
                  : Text('${lecon.numero}',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: isCurrent ? Colors.white : Colors.grey.shade500)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lecon.titre,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? _primary : Colors.grey.shade700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.schedule_outlined, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(lecon.duree,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                if (lecon.hasPdf) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.picture_as_pdf_rounded, size: 11,
                      color: Colors.redAccent.shade100),
                  const SizedBox(width: 2),
                  Text('PDF', style: TextStyle(
                      fontSize: 10, color: Colors.redAccent.shade100,
                      fontWeight: FontWeight.w600)),
                ],
              ]),
            ]),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _teal, borderRadius: BorderRadius.circular(8)),
              child: const Text('En cours',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            )
          else
            Icon(Icons.play_circle_outline_rounded, size: 20, color: Colors.grey.shade300),
        ]),
      ),
    );
  }

  // ── FAB Question forum ────────────────────────────────────────
  Widget _buildFabQuestion() => Positioned(
    bottom: 24, right: 20,
    child: ScaleTransition(
      scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
      child: GestureDetector(
        onTap: _ouvrirQuestionForum,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),  // Bleu distinctif pour les questions leçon
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Poser une question',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ),
    ),
  );
}
