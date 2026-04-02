// lib/views/pages/apprenants/lecture_lecon_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_fabs.dart';

const String _base = 'https://yeki.pythonanywhere.com/api';
const Color _teal = Color(0xFF008088);
const Color _navy = Color(0xFF0D1B2A);
const Color _gold = Color(0xFFE2A84B);
const Color _bg = Color(0xFFF0F4F8);

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
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
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
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    final lecon = _leconCourante;
    if (lecon == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Leçon introuvable'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, Color(0xFF1A3A5C)],
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
                        color: Colors.white, size: 18),
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
                                  color: Colors.white54,
                                  fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Row(children: [
                            Expanded(
                              child: Text(
                                'Leçon ${lecon.numero} — ${lecon.titre}',
                                style: const TextStyle(
                                    color: Colors.white,
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
                              color: Colors.white54,
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
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: lecon.estTerminee
                                ? Colors.green.withOpacity(0.4)
                                : Colors.white24),
                      ),
                      child: _marquageLoading
                          ? const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Icon(
                              lecon.estTerminee
                                  ? Icons.check_circle_rounded
                                  : Icons.check_rounded,
                              size: 16,
                              color: lecon.estTerminee
                                  ? Colors.green
                                  : Colors.white70),
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
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_pdfCurrent / $_pdfPages',
                      style: const TextStyle(
                          color: Colors.white60,
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
      color: _bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.article_outlined,
                  size: 64, color: _teal.withOpacity(0.4)),
            ),
            const SizedBox(height: 20),
            Text('Aucun PDF disponible',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Cette leçon sera disponible prochainement.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            if (lecon.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Text(lecon.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.6),
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
      color: _bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _teal, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Chargement du document...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfError() {
    return Container(
      color: _bg,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_pdfError ?? 'Erreur de chargement',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_leconCourante != null) _chargerPdf(_leconCourante!);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Réessayer',
                style: TextStyle(color: Colors.white)),
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
            child: CustomPaint(painter: _YekiWatermarkPainter()),
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
        color: const Color(0xFF161B22),
        border: const Border(top: BorderSide(color: Color(0xFF30363D))),
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
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _teal.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.arrow_back_ios_rounded,
                      color: _teal, size: 12),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(prev.titre,
                        style: const TextStyle(
                            color: _teal, fontSize: 11,
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
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _teal.withOpacity(0.2)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(next.titre,
                            style: const TextStyle(
                                color: _teal, fontSize: 11,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: _teal, size: 12),
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
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Row(children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toutes les leçons',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                      Text('${_toutesLecons.length} leçons • '
                          '${(_progression * 100).toInt()}% terminé',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ]),
              ),
            ]),
          ),
          LinearProgressIndicator(
            value: _progression,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(_teal),
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
                          ? _teal.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isCur
                              ? _teal.withOpacity(0.4)
                              : Colors.transparent),
                    ),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: isCur
                              ? _teal
                              : l.estTerminee
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: l.estTerminee && !isCur
                              ? Icon(Icons.check_rounded,
                                  color: Colors.green.shade400, size: 16)
                              : Text('${l.numero}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isCur
                                          ? Colors.white
                                          : Colors.white54)),
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
                                          ? Colors.white
                                          : Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Row(children: [
                                if (l.hasPdf) ...[
                                  Icon(Icons.picture_as_pdf_rounded,
                                      size: 10,
                                      color: Colors.redAccent.shade200),
                                  const SizedBox(width: 3),
                                  Text('PDF',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.redAccent.shade200,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                ],
                                if (l.duree.isNotEmpty)
                                  Text(l.duree,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38)),
                              ]),
                            ]),
                      ),
                      if (isCur)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('En cours',
                              style: TextStyle(
                                  color: Colors.white,
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
  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: Color(0x0A2884A0),
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