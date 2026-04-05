import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_fabs.dart';

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
const Color _gold = Color(0xFFE2A84B);
//const Color _navy = Color(0xFF1A2A3A);

const String _base = 'https://yeki.pythonanywhere.com/api';

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

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

class LectureLeconPage extends StatefulWidget {
  final int leconId;
  final int coursId;
  final String coursTitre;
  final int coursColor;

  const LectureLeconPage({
    super.key,
    required this.leconId,
    required this.coursId,
    required this.coursTitre,
    required this.coursColor,
  });

  @override
  State<LectureLeconPage> createState() => _LectureLeconPageState();
}

class _LectureLeconPageState extends State<LectureLeconPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  Lecon? _leconCourante;
  List<Lecon> _toutesLecons = [];
  double _progression = 0.0;

  bool _pdfLoading = false;
  String? _pdfPath;
  String? _pdfError;
  int _pdfPages = 0;
  int _pdfCurrent = 1;
  bool _pdfReady = false;
  PDFViewController? _pdfCtrl;
  bool _marquageLoading = false;

  bool _drawerOpen = false;
  late AnimationController _drawerCtrl;
  late AnimationController _fabCtrl;
  final ScrollController _listScrollCtrl = ScrollController();

  Color get _courseColor => Color(widget.coursColor);

  @override
  void initState() {
    super.initState();
    _drawerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _charger();
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    _fabCtrl.dispose();
    _listScrollCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    try {
      final res = await http.get(
        Uri.parse('$_base/cours/${widget.coursId}/liste-modules/'),
        headers: _headers(token),
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
          orElse: () => toutes.isNotEmpty ? toutes.first : Lecon(
            id: widget.leconId, titre: 'Leçon',
            duree: '', description: '', numero: 1),
        );

        final terminees = toutes.where((l) => l.estTerminee).length;
        final prog = toutes.isEmpty ? 0.0 : terminees / toutes.length;

        setState(() {
          _toutesLecons = toutes;
          _leconCourante = courante;
          _progression = prog;
          _loading = false;
        });

        _marquerVue(10);
        if (courante.hasPdf) _chargerPdf(courante);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marquerVue(int pct) async {
    final lecon = _leconCourante;
    if (lecon == null) return;

    final token = await _getToken();
    try {
      await http.post(
        Uri.parse('$_base/apprenant/marquer-lecon/'),
        headers: _headers(token),
        body: jsonEncode({'lecon_id': lecon.id, 'pourcentage': pct}),
      );
    } catch (_) {}
  }

  Future<void> _marquerTerminee() async {
    if (_marquageLoading) return;
    setState(() => _marquageLoading = true);
    await _marquerVue(100);
    if (mounted) {
      setState(() => _marquageLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✓ Leçon marquée comme terminée'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _chargerPdf(Lecon lecon) async {
    if (lecon.pdfUrl.isEmpty) return;

    setState(() { _pdfLoading = true; _pdfError = null; _pdfPath = null; _pdfReady = false; });

    try {
      final token = await _getToken();
      final url = lecon.pdfUrl.startsWith('http')
          ? lecon.pdfUrl
          : '$_base${lecon.pdfUrl}';

      final res = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Token $token'} : {},
      );

      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/lecon_${lecon.id}.pdf');
        await file.writeAsBytes(res.bodyBytes);
        if (mounted) setState(() { _pdfPath = file.path; _pdfLoading = false; });
      } else {
        if (mounted) setState(() {
          _pdfError = 'Impossible de charger le PDF (${res.statusCode})';
          _pdfLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _pdfError = 'Erreur réseau'; _pdfLoading = false; });
    }
  }

  void _changerLecon(Lecon lecon) {
    setState(() {
      _leconCourante = lecon;
      _pdfPath = null;
      _pdfReady = false;
      _pdfError = null;
      _pdfPages = 0;
      _pdfCurrent = 1;
      _pdfCtrl = null;
      _drawerOpen = false;
    });
    _drawerCtrl.reverse();
    _fabCtrl.forward(from: 0);
    _marquerVue(10);
    if (lecon.hasPdf) _chargerPdf(lecon);
  }

  Lecon? get _leconPrecedente {
    final idx = _toutesLecons.indexWhere((l) => l.id == _leconCourante?.id);
    return idx > 0 ? _toutesLecons[idx - 1] : null;
  }

  Lecon? get _leconSuivante {
    final idx = _toutesLecons.indexWhere((l) => l.id == _leconCourante?.id);
    return idx >= 0 && idx < _toutesLecons.length - 1
        ? _toutesLecons[idx + 1]
        : null;
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
        backgroundColor: _bgLight,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Leçon introuvable', style: TextStyle(color: _textMedium)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _courseColor,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retour')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(children: [
            _buildTopBar(lecon),
            Expanded(child: _buildPdfZone(lecon)),
            _buildBottomBar(),
          ]),
          AnimatedBuilder(
            animation: _drawerCtrl,
            builder: (_, __) {
              final slide = CurvedAnimation(parent: _drawerCtrl, curve: Curves.easeOutCubic);
              return slide.value > 0
                  ? Stack(children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _drawerOpen = false);
                          _drawerCtrl.reverse();
                        },
                        child: Container(
                          color: Colors.black.withOpacity(0.5 * slide.value),
                        ),
                      ),
                      Positioned(
                        top: 0, bottom: 0, left: 0,
                        width: MediaQuery.of(context).size.width * 0.78,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          ).animate(slide),
                          child: _buildLeconList(lecon),
                        ),
                      ),
                    ])
                  : const SizedBox.shrink();
            },
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: YekiFabs(
              coursId: widget.coursId,
              coursTitre: widget.coursTitre,
              coursColor: widget.coursColor,
              source: 'lecon',
              sourceId: lecon.id,
              sourceTitre: lecon.titre,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Lecon lecon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_courseColor, _courseColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _drawerOpen = !_drawerOpen);
                        _drawerOpen
                            ? _drawerCtrl.forward()
                            : _drawerCtrl.reverse();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.coursTitre,
                              style: const TextStyle(
                                  color: _white,
                                  fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Row(children: [
                            Expanded(
                              child: Text(
                                'Leçon ${lecon.numero} — ${lecon.titre}',
                                style: const TextStyle(
                                    color: _white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _drawerOpen
                                  ? Icons.keyboard_arrow_left_rounded
                                  : Icons.list_rounded,
                              color: _white,
                              size: 18,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _marquageLoading ? null : _marquerTerminee,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: lecon.estTerminee
                            ? _green.withOpacity(0.2)
                            : _white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: lecon.estTerminee
                                ? _green.withOpacity(0.4)
                                : _white),
                      ),
                      child: _marquageLoading
                          ? const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  color: _white, strokeWidth: 2))
                          : Icon(
                              lecon.estTerminee
                                  ? Icons.check_circle_rounded
                                  : Icons.check_rounded,
                              size: 16,
                              color: lecon.estTerminee
                                  ? _green
                                  : _white),
                    ),
                  ),
                ],
              ),
            ),
            if (_pdfReady && _pdfPages > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _pdfCurrent / _pdfPages,
                        backgroundColor: _white,
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_pdfCurrent / $_pdfPages',
                      style: const TextStyle(
                          color: _white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfZone(Lecon lecon) {
    if (!lecon.hasPdf) return _buildNoPdfPlaceholder(lecon);
    if (_pdfLoading) return _buildPdfLoading();
    if (_pdfError != null) return _buildPdfError();
    if (_pdfPath != null) return _buildPdfViewer();
    return _buildPdfLoading();
  }

  Widget _buildNoPdfPlaceholder(Lecon lecon) {
    return Container(
      color: _bgLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _courseColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _courseColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.article_outlined,
                  size: 64, color: _courseColor.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            Text('Aucun PDF disponible',
                style: TextStyle(
                    fontSize: 16,
                    color: _textMedium,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Cette leçon sera disponible prochainement.',
                style: TextStyle(fontSize: 13, color: _textLight)),
            if (lecon.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderLight, width: 1),
                ),
                child: Text(lecon.description,
                    style: TextStyle(fontSize: 13, color: _textMedium, height: 1.6),
                    textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfLoading() {
    return Container(
      color: _bgLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Chargement du document...',
                style: TextStyle(color: _textLight, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfError() {
    return Container(
      color: _bgLight,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_pdfError ?? 'Erreur de chargement',
              style: TextStyle(color: _textMedium),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_leconCourante != null) _chargerPdf(_leconCourante!);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _courseColor,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            icon: const Icon(Icons.refresh_rounded, color: _white),
            label: const Text('Réessayer',
                style: TextStyle(color: _white)),
          ),
        ]),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: _pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          nightMode: false,
          onRender: (pages) {
            if (mounted) setState(() { _pdfPages = pages ?? 0; _pdfReady = true; });
          },
          onViewCreated: (ctrl) {
            if (mounted) setState(() => _pdfCtrl = ctrl);
          },
          onPageChanged: (page, total) {
            if (mounted) setState(() {
              _pdfCurrent = (page ?? 0) + 1;
              _pdfPages = total ?? _pdfPages;
              if (_pdfPages > 0 && _pdfCurrent >= _pdfPages ~/ 2) _marquerVue(50);
              if (_pdfPages > 0 && _pdfCurrent >= _pdfPages) _marquerVue(100);
            });
          },
          onError: (e) {
            if (mounted) setState(() => _pdfError = 'Erreur PDF: $e');
          },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _YekiWatermarkPainter(courseColor: _courseColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final prev = _leconPrecedente;
    final next = _leconSuivante;

    return Container(
      padding: EdgeInsets.only(
          left: 12, right: 12, top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: _white,
        border: const Border(top: BorderSide(color: _borderLight)),
      ),
      child: Row(children: [
        if (prev != null)
          Expanded(
            child: GestureDetector(
              onTap: () => _changerLecon(prev),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _courseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _courseColor.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  const Icon(Icons.arrow_back_ios_rounded,
                      color: brandBackground, size: 12),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(prev.titre,
                        style: TextStyle(
                            color: _courseColor, fontSize: 11,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
        if (prev != null && next != null) const SizedBox(width: 8),
        if (next != null)
          Expanded(
            child: GestureDetector(
              onTap: () => _changerLecon(next),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _courseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _courseColor.withOpacity(0.2), width: 1),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(next.titre,
                            style: TextStyle(
                                color: _courseColor, fontSize: 11,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: brandBackground, size: 12),
                    ]),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ]),
    );
  }

  Widget _buildLeconList(Lecon courante) {
    return Container(
      color: _white,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: _white,
              border: Border(bottom: BorderSide(color: _borderLight)),
            ),
            child: Row(children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                    color: _courseColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toutes les leçons',
                        style: TextStyle(
                            color: _textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                      Text('${_toutesLecons.length} leçons • '
                          '${(_progression * 100).toInt()}% terminé',
                          style: TextStyle(
                              color: _textLight, fontSize: 11)),
                    ]),
              ),
            ]),
          ),
          LinearProgressIndicator(
            value: _progression,
            backgroundColor: _borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(_courseColor),
            minHeight: 3,
          ),
          Expanded(
            child: ListView.builder(
              controller: _listScrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _toutesLecons.length,
              itemBuilder: (ctx, i) {
                final l = _toutesLecons[i];
                final isCur = l.id == courante.id;

                return GestureDetector(
                  onTap: () => _changerLecon(l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCur
                          ? _courseColor.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isCur
                              ? _courseColor.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: isCur
                              ? _courseColor
                              : l.estTerminee
                                  ? _green.withOpacity(0.1)
                                  : _bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isCur
                                  ? _courseColor
                                  : _borderLight,
                              width: isCur ? 0 : 1),
                        ),
                        child: Center(
                          child: l.estTerminee && !isCur
                              ? Icon(Icons.check_rounded,
                                  color: _green, size: 16)
                              : Text('${l.numero}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isCur
                                          ? _white
                                          : _textMedium)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.titre,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCur
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isCur
                                          ? _courseColor
                                          : _textDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Row(children: [
                                if (l.hasPdf) ...[
                                  Icon(Icons.picture_as_pdf_rounded,
                                      size: 10,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 3),
                                  Text('PDF',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                ],
                                if (l.duree.isNotEmpty)
                                  Text(l.duree,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: _textLight)),
                              ]),
                            ]),
                      ),
                      if (isCur)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _courseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('En cours',
                              style: TextStyle(
                                  color: _white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _YekiWatermarkPainter extends CustomPainter {
  final Color courseColor;

  const _YekiWatermarkPainter({required this.courseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: courseColor.withOpacity(0.05),
      fontSize: 26,
      fontWeight: FontWeight.w900,
      letterSpacing: 3,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: 'Yéki', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.5);
    canvas.translate(-size.width / 2, -size.height / 2);

    const spacingX = 140.0;
    const spacingY = 100.0;

    for (double y = -100; y < size.height + 100; y += spacingY) {
      for (double x = -80; x < size.width + 80; x += spacingX) {
        textPainter.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}