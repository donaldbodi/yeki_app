import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';

const String _dBase = 'https://yeki.pythonanywhere.com/api';
// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
//const Color _borderMedium = Color(0xFFD0D4D8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _blue = Color(0xFF3B82F6);
const Color _purple = Color(0xFF8B5CF6);
const Color _orange = Color(0xFFF97316);
const Color _red = Color(0xFFEF4444);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _hdrs(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ============================================================
// MODÈLE LEÇON
// ============================================================
class Lecon {
  final int id;
  final String titre;
  final String duree;
  final String description;
  final bool hasPdf;
  final bool estTerminee;
  final String videoUrl;
  final String pdfUrl;
  final int numero;

  const Lecon({
    required this.id,
    required this.titre,
    required this.duree,
    required this.description,
    this.hasPdf = false,
    this.estTerminee = false,
    this.videoUrl = '',
    this.pdfUrl = '',
    required this.numero,
  });

  factory Lecon.fromJson(Map<String, dynamic> j, {int numero = 1}) => Lecon(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
    titre: j['titre'] ?? '',
    duree: j['duree'] ?? '',
    description: j['description'] ?? '',
    hasPdf: (j['fichier_pdf'] ?? '').toString().isNotEmpty,
    estTerminee: j['est_terminee'] ?? false,
    videoUrl: j['video'] ?? '',
    pdfUrl: j['fichier_pdf'] ?? '',
    numero: j['ordre'] ?? numero,
  );
}

// ============================================================
// PAGE PRINCIPALE
// ============================================================
class DetailLeconPage extends StatefulWidget {
  final int leconId;
  final int coursId;
  final String coursTitre;
  final int coursColor;

  const DetailLeconPage({
    super.key,
    required this.leconId,
    required this.coursId,
    required this.coursTitre,
    required this.coursColor,
  });

  @override
  State<DetailLeconPage> createState() => _DetailLeconPageState();
}

class _DetailLeconPageState extends State<DetailLeconPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  Lecon? _leconCourante;
  List<Lecon> _toutesLecons = [];
  double _progression = 0.0;
  bool _isFullscreen = false;
  bool _isVideoPlaying = false;
  bool _showControls = true;
  bool _isLiked = false;
  bool _marquageLoading = false;

  late AnimationController _controlsCtrl;
  late AnimationController _fabCtrl;
  late Animation<double> _controlsAnim;
  final ScrollController _scrollCtrl = ScrollController();

  Color get _courseColor => Color(widget.coursColor);

  @override
  void initState() {
    super.initState();
    _controlsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controlsAnim = CurvedAnimation(parent: _controlsCtrl, curve: Curves.easeOut);
    _controlsCtrl.value = 1.0;
    _fabCtrl.forward();
    _charger();
    _verifierLike();
  }

  @override
  void dispose() {
    _controlsCtrl.dispose();
    _fabCtrl.dispose();
    _scrollCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        Uri.parse('$_dBase/cours/${widget.coursId}/liste-modules/'),
        headers: _hdrs(token),
      );

      if (res.statusCode == 200) {
        final modules = jsonDecode(res.body) as List;
        final List<Lecon> toutes = [];
        int numero = 1;

        for (final module in modules) {
          for (final l in (module['lecons'] as List? ?? [])) {
            toutes.add(Lecon.fromJson(l, numero: numero++));
          }
        }

        final courante = toutes.firstWhere(
          (l) => l.id == widget.leconId,
          orElse: () => toutes.isNotEmpty ? toutes.first
              : Lecon(id: widget.leconId, titre: 'Leçon', duree: '', description: '', numero: 1),
        );

        final term = toutes.where((l) => l.estTerminee).length;
        setState(() {
          _toutesLecons = toutes;
          _leconCourante = courante;
          _progression = toutes.isEmpty ? 0 : term / toutes.length;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifierLike() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('$_dBase/apprenant/lecon/${widget.leconId}/like/'),
        headers: _hdrs(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isLiked = data['liked'] ?? false);
      }
    } catch (_) {}
  }

  Future<void> _marquerTerminee() async {
    final lecon = _leconCourante;
    if (lecon == null || lecon.estTerminee) return;
    setState(() => _marquageLoading = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _marquageLoading = false);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('$_dBase/apprenant/marquer-lecon/'),
        headers: _hdrs(token),
        body: jsonEncode({'lecon_id': lecon.id, 'pourcentage': 100}),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        await _charger();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Leçon marquée comme terminée'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _marquageLoading = false);
  }

  Future<void> _toggleLike() async {
    final lecon = _leconCourante;
    if (lecon == null) return;

    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLiked = !_isLiked);

    try {
      await http.post(
        Uri.parse('$_dBase/apprenant/lecon/${lecon.id}/like/'),
        headers: _hdrs(token),
      );
    } catch (_) {
      setState(() => _isLiked = !_isLiked);
    }
  }

  void _changerLecon(Lecon lecon) {
    setState(() {
      _leconCourante = lecon;
      _isVideoPlaying = false;
      _showControls = true;
      _controlsCtrl.value = 1.0;
    });
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _ouvrirPdf() {
    final lecon = _leconCourante;
    if (lecon == null || !lecon.hasPdf) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LectureLeconPage(
          leconId: lecon.id,
          coursId: widget.coursId,
          coursTitre: widget.coursTitre,
          coursColor: widget.coursColor,
        ),
      ),
    );
  }

  void _ouvrirIA() {
    final lecon = _leconCourante;
    if (lecon == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IAChoixSheet(
        onVoirDiscussion: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YekiIAChatPage(
                coursId: widget.coursId,
                coursTitre: widget.coursTitre,
                sourceInitiale: 'lecon',
                sourceId: lecon.id,
                sourceTitreInit: lecon.titre,
              ),
            ),
          );
        },
        onPoserPreoccupation: () {
          Navigator.pop(ctx);
          _afficherFormulaireIA(lecon);
        },
      ),
    );
  }

  void _afficherFormulaireIA(Lecon lecon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PreoccupationSheet(
        titre: 'Poser à Yéki IA',
        accentColor: _courseColor,
        isIA: true,
        source: 'lecon',
        sourceId: lecon.id,
        sourceTitre: lecon.titre,
        coursId: widget.coursId,
        coursTitre: widget.coursTitre,
        coursColor: widget.coursColor,
        onSoumis: (String texte) async {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YekiIAChatPage(
                coursId: widget.coursId,
                coursTitre: widget.coursTitre,
                sourceInitiale: 'lecon',
                sourceId: lecon.id,
                sourceTitreInit: lecon.titre,
                messageInitial: texte,
              ),
            ),
          );
        },
      ),
    );
  }

  void _ouvrirForum() {
    final lecon = _leconCourante;
    if (lecon == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PreoccupationSheet(
        titre: 'Poster dans le Forum',
        accentColor: _blue,
        isIA: false,
        source: 'lecon',
        sourceId: lecon.id,
        sourceTitre: lecon.titre,
        coursId: widget.coursId,
        coursTitre: widget.coursTitre,
        coursColor: widget.coursColor,
        onSoumis: (String texte) async {
          Navigator.pop(ctx);
          final token = await _getToken();
          if (token == null) return;

          try {
            final res = await http.post(
              Uri.parse('$_dBase/forum/questions/'),
              headers: _hdrs(token),
              body: jsonEncode({
                'contenu': texte,
                'source': 'lecon',
                'lecon_id': lecon.id,
                'lecon_titre': lecon.titre,
                'cours_id': widget.coursId,
                'cours_titre': widget.coursTitre,
              }),
            );

            if (res.statusCode == 201 && mounted) {
              final data = jsonDecode(res.body);
              final questionId = data['id'];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoursDetailTabs(
                    coursId: widget.coursId.toString(),
                    titre: widget.coursTitre,
                    coursColor: widget.coursColor,
                    isPremium: true,
                    initialTab: 3,
                    scrollToQuestionId: questionId,
                  ),
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✓ Question postée dans le forum !'),
                  backgroundColor: _blue,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de l\'envoi'),
                backgroundColor: _red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsCtrl.forward();
    } else {
      _controlsCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lecon = _leconCourante;
    if (lecon == null) {
      return Scaffold(
        body: Center(child: Text('Leçon introuvable', style: TextStyle(color: _textMedium))),
      );
    }

    if (_isFullscreen) return _buildFullscreenVideo(lecon);

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Column(
            children: [
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
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 28,
            right: 18,
            child: _buildFabs(),
          ),
        ],
      ),
    );
  }

  Widget _buildFabs() => ScaleTransition(
    scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FabCircle(
          icon: Icons.psychology_rounded,
          gradient: LinearGradient(
            colors: [_courseColor, _courseColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          tooltip: 'Yéki IA',
          onTap: _ouvrirIA,
        ),
        const SizedBox(height: 12),
        _FabCircle(
          icon: Icons.forum_rounded,
          gradient: const LinearGradient(
            colors: [_blue, Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          tooltip: 'Forum',
          onTap: _ouvrirForum,
        ),
      ],
    ),
  );

  Widget _buildVideoZone(Lecon lecon) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_courseColor, _courseColor.withOpacity(0.6)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _controlsAnim,
                builder: (_, __) => Opacity(
                  opacity: _controlsAnim.value,
                  child: GestureDetector(
                    onTap: () => setState(() => _isVideoPlaying = !_isVideoPlaying),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _isVideoPlaying ? _white.withOpacity(0.15) : _courseColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _white.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(
                        _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildVideoTopBar(lecon),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildVideoBottomBar(),
            ),
          ],
        ),
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
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: _white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lecon.titre,
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _courseColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Leçon ${lecon.numero}',
                style: const TextStyle(
                  color: _white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: _courseColor,
                inactiveTrackColor: _white.withOpacity(0.3),
                thumbColor: _white,
                overlayColor: _white.withOpacity(0.2),
              ),
              child: const Slider(value: 0.35, onChanged: null),
            ),
            Row(
              children: [
                const Text('6:18', style: TextStyle(color: _white, fontSize: 11)),
                const Spacer(),
                const Text('18:00', style: TextStyle(color: _white, fontSize: 11)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleFullscreen,
                  child: const Icon(Icons.fullscreen_rounded, color: _white, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildFullscreenVideo(Lecon lecon) => Scaffold(
    backgroundColor: Colors.black,
    body: GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_courseColor, _courseColor.withOpacity(0.6)],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isVideoPlaying = !_isVideoPlaying),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _courseColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: _white.withOpacity(0.2), width: 1),
                ),
                child: Icon(
                  _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: _white,
                  size: 36,
                ),
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC000000), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleFullscreen,
                          child: const Icon(Icons.fullscreen_exit_rounded, color: _white, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            lecon.titre,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            activeTrackColor: _courseColor,
                            inactiveTrackColor: _white.withOpacity(0.3),
                            thumbColor: _white,
                          ),
                          child: const Slider(value: 0.35, onChanged: null),
                        ),
                        Row(
                          children: [
                            const Text('6:18', style: TextStyle(color: _white, fontSize: 12)),
                            const Spacer(),
                            const Text('18:00', style: TextStyle(color: _white, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLeconHeader(Lecon lecon) => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _courseColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${lecon.numero}',
                  style: const TextStyle(
                    color: _white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecon.titre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 13, color: _textLight),
                      const SizedBox(width: 4),
                      Text(
                        lecon.duree,
                        style: TextStyle(fontSize: 12, color: _textLight),
                      ),
                      const SizedBox(width: 12),
                      if (lecon.estTerminee) ...[
                        Icon(Icons.check_circle_rounded, size: 13, color: _green),
                        const SizedBox(width: 4),
                        Text(
                          'Terminée',
                          style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isLiked ? Colors.red.withOpacity(0.1) : _bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderLight, width: 1),
                ),
                child: Icon(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? _red : _textLight,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Progression du cours',
              style: TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${(_progression * 100).toInt()}%',
              style: TextStyle(fontSize: 11, color: _courseColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progression,
            backgroundColor: _borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(_courseColor),
            minHeight: 6,
          ),
        ),
      ],
    ),
  );

  Widget _buildActionsRapides(Lecon lecon) => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: _borderLight, height: 1),
        const SizedBox(height: 16),
        Text(
          'Actions',
          style: TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Lire PDF',
              color: _red,
              enabled: lecon.hasPdf,
              onTap: _ouvrirPdf,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.check_circle_outline_rounded,
              label: 'Fait',
              color: _green,
              enabled: !lecon.estTerminee,
              onTap: _marquerTerminee,
              loading: _marquageLoading,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.psychology_rounded,
              label: 'Yéki IA',
              color: _courseColor,
              enabled: true,
              onTap: _ouvrirIA,
            ),
            const SizedBox(width: 8),
            _actionBtn(
              icon: Icons.forum_rounded,
              label: 'Forum',
              color: _blue,
              enabled: true,
              onTap: _ouvrirForum,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: enabled && !loading ? onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: enabled ? color.withOpacity(0.08) : _bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: enabled ? color.withOpacity(0.2) : _borderLight,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: color),
                        )
                      : Icon(icon, color: enabled ? color : _textLight, size: 22),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: enabled ? color : _textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildDescription(Lecon lecon) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _borderLight, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: _courseColor),
            const SizedBox(width: 8),
            Text(
              'À propos de cette leçon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          lecon.description,
          style: TextStyle(fontSize: 13.5, color: _textMedium, height: 1.6),
        ),
      ],
    ),
  );

  Widget _buildListeLecons() {
    if (_toutesLecons.isEmpty) return const SizedBox.shrink();
    final lecon = _leconCourante;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.playlist_play_rounded, size: 18, color: _courseColor),
                const SizedBox(width: 8),
                Text(
                  'Toutes les leçons',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _courseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_toutesLecons.length} leçons',
                    style: TextStyle(fontSize: 10, color: _courseColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ..._toutesLecons.map((l) => _buildLeconTile(l, lecon)),
          const SizedBox(height: 8),
        ],
      ),
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
          color: isCurrent ? _courseColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCurrent ? _courseColor : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCurrent
                    ? _courseColor
                    : lecon.estTerminee
                        ? _green.withOpacity(0.1)
                        : _bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? _courseColor : _borderLight,
                  width: isCurrent ? 0 : 1,
                ),
              ),
              child: Center(
                child: lecon.estTerminee && !isCurrent
                    ? Icon(Icons.check_rounded, color: _green, size: 16)
                    : Text(
                        '${lecon.numero}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isCurrent ? _white : _textMedium,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecon.titre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? _courseColor : _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 11, color: _textLight),
                      const SizedBox(width: 3),
                      Text(
                        lecon.duree,
                        style: TextStyle(fontSize: 11, color: _textLight),
                      ),
                      if (lecon.hasPdf) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.picture_as_pdf_rounded, size: 11, color: _red),
                        const SizedBox(width: 2),
                        Text(
                          'PDF',
                          style: TextStyle(fontSize: 10, color: _red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _courseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'En cours',
                  style: TextStyle(color: _white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              )
            else
              Icon(Icons.play_circle_outline_rounded, size: 20, color: _textLight),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FAB CIRCULAIRE
// ============================================================
class _FabCircle extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String tooltip;
  final VoidCallback onTap;

  const _FabCircle({
    required this.icon,
    required this.gradient,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: _white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: _white, size: 24),
      ),
    ),
  );
}

// ============================================================
// CHOIX IA SHEET
// ============================================================
class _IAChoixSheet extends StatelessWidget {
  final VoidCallback onVoirDiscussion;
  final VoidCallback onPoserPreoccupation;

  const _IAChoixSheet({
    required this.onVoirDiscussion,
    required this.onPoserPreoccupation,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: _borderLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF135F74), Color(0xFF2884A0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'YIA',
                  style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Yéki IA',
              style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _opt(
          icon: Icons.chat_rounded,
          label: 'Voir la discussion',
          sub: 'Reprendre la conversation IA',
          color: brandBackground,
          onTap: onVoirDiscussion,
        ),
        const SizedBox(height: 10),
        _opt(
          icon: Icons.psychology_alt_rounded,
          label: 'Poser une préoccupation',
          sub: 'Expliquer un problème (+ image)',
          color: _purple,
          onTap: onPoserPreoccupation,
        ),
      ],
    ),
  );

  Widget _opt({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      sub,
                      style: TextStyle(color: _textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      );
}

// ============================================================
// FORMULAIRE PRÉOCCUPATION
// ============================================================
class _PreoccupationSheet extends StatefulWidget {
  final String titre;
  final Color accentColor;
  final bool isIA;
  final String source;
  final int? sourceId;
  final String sourceTitre;
  final int? coursId;
  final String? coursTitre;
  final int? coursColor;
  final void Function(String) onSoumis;

  const _PreoccupationSheet({
    required this.titre,
    required this.accentColor,
    required this.isIA,
    required this.source,
    this.sourceId,
    this.sourceTitre = '',
    this.coursId,
    this.coursTitre,
    this.coursColor,
    required this.onSoumis,
  });

  @override
  State<_PreoccupationSheet> createState() => _PreoccupationSheetState();
}

class _PreoccupationSheetState extends State<_PreoccupationSheet> {
  final _ctrl = TextEditingController();
  File? _image;
  bool _sending = false;

  static const Map<String, Color> _sc = {
    'lecon': _blue,
    'exercice': _purple,
    'devoir': _orange,
    'libre': _green,
  };

  static const Map<String, IconData> _si = {
    'lecon': Icons.play_lesson_rounded,
    'exercice': Icons.edit_note_rounded,
    'devoir': Icons.assignment_rounded,
    'libre': Icons.chat_bubble_outline_rounded,
  };

  static const Map<String, String> _sl = {
    'lecon': 'Leçon',
    'exercice': 'Exercice',
    'devoir': 'Devoir',
    'libre': 'Libre',
  };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _sc[widget.source] ?? widget.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isIA ? Icons.psychology_rounded : Icons.forum_rounded,
                    color: widget.accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.titre,
                  style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.source != 'libre' && widget.sourceTitre.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sc.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(_si[widget.source] ?? Icons.link_rounded, color: sc, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_sl[widget.source] ?? widget.source} : ${widget.sourceTitre}',
                        style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: _bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: _textDark, fontSize: 14),
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: widget.isIA
                      ? 'Décrivez votre problème à Yéki IA…'
                      : 'Décrivez votre préoccupation au forum…',
                  hintStyle: TextStyle(color: _textLight, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _image != null ? _green.withOpacity(0.08) : _bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _image != null ? _green.withOpacity(0.4) : _borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _image != null ? Icons.check_circle_rounded : Icons.image_outlined,
                      color: _image != null ? _green : _textLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _image != null ? 'Image ajoutée' : 'Ajouter une image',
                      style: TextStyle(
                        color: _image != null ? _green : _textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_sending || _ctrl.text.trim().isEmpty)
                    ? null
                    : () {
                        setState(() => _sending = true);
                        widget.onSoumis(_ctrl.text.trim());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _sending
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.isIA ? Icons.send_rounded : Icons.forum_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            widget.isIA ? 'Envoyer à Yéki IA' : 'Poster dans le Forum',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}