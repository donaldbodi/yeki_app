// lib/views/pages/apprenants/detail_lecon_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// DÉTAIL LEÇON — VERSION PERFORMANTE (SANS BackdropFilter)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:yeki/views/pages/apprenants/lecture_lecon_page.dart';
import 'package:yeki/views/pages/apprenants/yeki_ia_chat_page.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

const double _videoHeight = 220.0;

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

class Lecon {
  final int id;
  final String titre;
  final String duree;
  final String description;
  final bool hasPdf;
  final bool hasVideo;
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
    this.hasVideo = false,
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
        hasVideo: (j['video'] ?? '').toString().isNotEmpty,
        estTerminee: j['est_terminee'] ?? false,
        videoUrl: j['video'] ?? '',
        pdfUrl: j['fichier_pdf'] ?? '',
        numero: j['ordre'] ?? numero,
      );
}

// ─── WIDGET VIDÉO ISOLÉ ────────────────────────────────────────────────
class VideoPlayerSection extends StatefulWidget {
  final VideoPlayerController controller;
  final Color accentColor;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;

  const VideoPlayerSection({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  late final AnimationController _controlsCtrl;
  late final Animation<double> _controlsAnim;

  @override
  void initState() {
    super.initState();
    _controlsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controlsAnim = CurvedAnimation(
      parent: _controlsCtrl,
      curve: Curves.easeInOut,
    );
    _controlsCtrl.value = 1.0;
    _startAutoHideTimer();
  }

  void _startAutoHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
          _controlsCtrl.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _controlsCtrl.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsCtrl.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _showControls) {
            setState(() {
              _showControls = false;
              _controlsCtrl.reverse();
            });
          }
        });
      } else {
        _controlsCtrl.reverse();
      }
    });
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;

    return Container(
      height: widget.isFullscreen ? double.infinity : _videoHeight,
      width: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video Player ──
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // ── Play/Pause Button ──
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _controlsAnim.value,
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom Controls ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _controlsAnim.value,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: widget.accentColor,
                          bufferedColor: Colors.white.withValues(alpha: 0.24),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDuration(value.position),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(value.duration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.38),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onToggleFullscreen,
                            child: Icon(
                              widget.isFullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAGE PRINCIPALE ────────────────────────────────────────────────────

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
  bool _isLiked = false;
  bool _marquageLoading = false;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  final ScrollController _scrollCtrl = ScrollController();

  Color get _courseColor => Color(widget.coursColor);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _charger();
      _verifierLike();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _disposeVideo();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  Future<void> _initVideo(String videoUrl) async {
    _disposeVideo();
    if (videoUrl.isEmpty) return;
    final fullUrl = videoUrl.startsWith('http')
        ? videoUrl
        : '${ApiConstants.baseUrl}$videoUrl';
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
      await controller.initialize();
      controller.setLooping(true);
      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur initialisation vidéo: $e');
      _disposeVideo();
    }
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.coursModules(widget.coursId)),
        headers: ApiHeaders.auth(token),
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
          orElse: () => toutes.isNotEmpty ? toutes.first : Lecon(id: widget.leconId, titre: 'Leçon', duree: '', description: '', numero: 1),
        );

        final totalLecons = toutes.length;
        final terminees = toutes.where((l) => l.estTerminee).length;
        final nouvelleProgression = totalLecons > 0 ? terminees / totalLecons : 0.0;

        if (mounted) {
          setState(() {
            _toutesLecons = toutes;
            _leconCourante = courante;
            _progression = nouvelleProgression;
            _loading = false;
          });
        }

        if (courante.hasVideo && courante.videoUrl.isNotEmpty) {
          _initVideo(courante.videoUrl);
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifierLike() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.leconLike(widget.leconId)),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _isLiked = data['liked'] ?? false);
      }
    } catch (_) {}
  }

  Future<void> _marquerTerminee() async {
    final lecon = _leconCourante;
    if (lecon == null || lecon.estTerminee) return;
    setState(() => _marquageLoading = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _marquageLoading = false);
      return;
    }
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.marquerLecon),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'lecon_id': lecon.id, 'pourcentage': 100}),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        await _charger();
        if (mounted) {
          ErrorHandler.showSuccess(context, '✓ Leçon marquée comme terminée');
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _marquageLoading = false);
  }

  Future<void> _toggleLike() async {
    final lecon = _leconCourante;
    if (lecon == null) return;
    final token = await _getToken();
    if (token == null) return;
    if (mounted) setState(() => _isLiked = !_isLiked);
    try {
      await http.post(
        Uri.parse(ApiConstants.leconLike(lecon.id)),
        headers: ApiHeaders.auth(token),
      );
    } catch (_) {
      if (mounted) setState(() => _isLiked = !_isLiked);
    }
  }

  void _changerLecon(Lecon lecon) {
    _disposeVideo();
    setState(() {
      _leconCourante = lecon;
    });
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    if (lecon.hasVideo && lecon.videoUrl.isNotEmpty) {
      _initVideo(lecon.videoUrl);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
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
        courseColor: _courseColor,
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
        onSoumis: (String texte, File? image, File? audio) async {
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) {
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
                  initialImage: image,
                  initialAudio: audio,
                ),
              ),
            );
          }
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
        accentColor: YekiColors.primary,
        isIA: false,
        source: 'lecon',
        sourceId: lecon.id,
        sourceTitre: lecon.titre,
        coursId: widget.coursId,
        coursTitre: widget.coursTitre,
        coursColor: widget.coursColor,
        onSoumis: (String texte, File? image, File? audio) async {
          if (ctx.mounted) {
            await _envoyerQuestionForum(texte, image, audio, ctx);
            if (ctx.mounted) Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  Future<void> _envoyerQuestionForum(
    String texte,
    File? image,
    File? audio,
    BuildContext ctx,
  ) async {
    final token = await _getToken();
    if (token == null) {
      if (ctx.mounted) {
        ErrorHandler.showError(ctx, 'Vous devez être connecté');
      }
      return;
    }

    final lecon = _leconCourante;
    if (lecon == null) {
      if (ctx.mounted) {
        ErrorHandler.showError(ctx, 'Leçon introuvable');
      }
      return;
    }

    if (texte.isEmpty && image == null && audio == null) {
      if (ctx.mounted) {
        ErrorHandler.showError(
          ctx,
          'Veuillez écrire un message, ajouter une image ou un enregistrement audio',
        );
      }
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.forumQuestions),
      );
      request.headers['Authorization'] = 'Token $token';

      request.fields['contenu'] = texte.isEmpty ? '[Message audio]' : texte;
      request.fields['source'] = 'lecon';
      request.fields['lecon_id'] = lecon.id.toString();
      request.fields['lecon_titre'] = lecon.titre;
      request.fields['cours_id'] = widget.coursId.toString();
      request.fields['cours_titre'] = widget.coursTitre;

      if (image != null && await image.exists()) {
        final imageBytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'question_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      if (audio != null && await audio.exists()) {
        final audioBytes = await audio.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: 'question_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 201 && ctx.mounted) {
        try {
          final data = jsonDecode(responseBody);
          final questionId = data['id'];
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
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
              }
            });
          }
        } catch (_) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoursDetailTabs(
                      coursId: widget.coursId.toString(),
                      titre: widget.coursTitre,
                      coursColor: widget.coursColor,
                      isPremium: true,
                      initialTab: 3,
                    ),
                  ),
                );
              }
            });
          }
        }
        if (ctx.mounted) {
          ErrorHandler.showSuccess(ctx, '✓ Question postée dans le forum !');
        }
      } else {
        String errorMsg = 'Erreur lors de l\'envoi';
        try {
          final errorData = jsonDecode(responseBody);
          errorMsg = errorData['detail'] ?? errorData['errors']?.toString() ?? errorMsg;
        } catch (_) {}
        if (ctx.mounted) {
          ErrorHandler.showError(ctx, errorMsg);
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ErrorHandler.showError(ctx, 'Erreur réseau: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: YekiColors.bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: YekiColors.primary),
        ),
      );
    }
    final lecon = _leconCourante;
    if (lecon == null) {
      return Scaffold(
        backgroundColor: YekiColors.bgLight,
        body: Center(
          child: Text(
            'Leçon introuvable',
            style: YekiTextStyles.body(context),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      body: Column(
        children: [
          // ── Vidéo ──
          if (_isVideoInitialized && _videoController != null)
            VideoPlayerSection(
              controller: _videoController!,
              accentColor: _courseColor,
              onToggleFullscreen: _toggleFullscreen,
              isFullscreen: _isFullscreen,
            )
          else if (lecon.hasVideo && !_isVideoInitialized)
            SizedBox(
              height: _videoHeight,
              width: double.infinity,
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: YekiColors.primary),
                ),
              ),
            )
          else
            SizedBox(
              height: _videoHeight,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      _courseColor.withValues(alpha: 0.3),
                      Colors.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam_off_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

          // ── Contenu ──
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FabCircle(
            icon: Icons.psychology_rounded,
            gradient: LinearGradient(
              colors: [_courseColor, _courseColor.withValues(alpha: 0.8)],
            ),
            tooltip: 'Yéki IA',
            onTap: _ouvrirIA,
          ),
          const SizedBox(height: 12),
          _FabCircle(
            icon: Icons.forum_rounded,
            gradient: const LinearGradient(
              colors: [YekiColors.primary, Color(0xFF60A5FA)],
            ),
            tooltip: 'Forum',
            onTap: _ouvrirForum,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────

  Widget _buildLeconHeader(Lecon lecon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecon.titre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _courseColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                size: 13,
                                color: YekiColors.textMedium,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lecon.duree,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lecon.estTerminee) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: YekiColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 13, color: YekiColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Terminée',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: YekiColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleLike,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isLiked
                        ? YekiColors.error.withValues(alpha: 0.06)
                        : YekiColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isLiked
                          ? YekiColors.error.withValues(alpha: 0.3)
                          : YekiColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? YekiColors.error : YekiColors.textMedium,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            key: ValueKey('prog_${(_progression * 100).toInt()}'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: YekiColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: YekiColors.borderLight, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Progression du cours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(_progression * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _courseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progression.clamp(0.0, 1.0),
                    backgroundColor: YekiColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_courseColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS RAPIDES ──────────────────────────────────────────────

  Widget _buildActionsRapides(Lecon lecon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          _actionBtn(
            icon: Icons.menu_book_rounded,
            label: 'Support PDF',
            color: YekiColors.error,
            enabled: lecon.hasPdf,
            onTap: _ouvrirPdf,
          ),
          const SizedBox(width: 10),
          _actionBtn(
            icon: Icons.task_alt_rounded,
            label: 'Complété',
            color: YekiColors.success,
            enabled: !lecon.estTerminee,
            onTap: _marquerTerminee,
            loading: _marquageLoading,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled && !loading ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: enabled
                  ? color.withValues(alpha: 0.06)
                  : YekiColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.2)
                    : YekiColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(icon, color: enabled ? color : YekiColors.textMedium, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enabled ? color : YekiColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── DESCRIPTION ───────────────────────────────────────────────────

  Widget _buildDescription(Lecon lecon) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: YekiColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lecon.description.isNotEmpty
                ? lecon.description
                : "Aucune description fournie pour cette leçon.",
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: YekiColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LISTE DES LEÇONS ─────────────────────────────────────────────

  Widget _buildListeLecons() {
    if (_toutesLecons.isEmpty) return const SizedBox.shrink();
    final lecon = _leconCourante;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, size: 18, color: _courseColor),
                const SizedBox(width: 8),
                const Text(
                  'Déroulé du cours',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _courseColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_toutesLecons.length} chapitres',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _courseColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: YekiColors.borderLight, height: 1),
          const SizedBox(height: 6),
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _toutesLecons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (ctx, idx) => _buildLeconTile(_toutesLecons[idx], lecon),
          ),
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
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? _courseColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? _courseColor.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent
                    ? _courseColor
                    : lecon.estTerminee
                        ? YekiColors.success.withValues(alpha: 0.08)
                        : YekiColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? _courseColor
                      : lecon.estTerminee
                          ? YekiColors.success.withValues(alpha: 0.2)
                          : YekiColors.borderLight,
                  width: 1,
                ),
              ),
              child: Center(
                child: lecon.estTerminee && !isCurrent
                    ? Icon(Icons.done_rounded, size: 16, color: YekiColors.success)
                    : Text(
                        '${lecon.numero}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isCurrent ? YekiColors.white : YekiColors.textMedium,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecon.titre,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? _courseColor : YekiColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined, size: 12, color: YekiColors.textLight),
                      const SizedBox(width: 4),
                      Text(lecon.duree, style: const TextStyle(fontSize: 11, color: YekiColors.textLight)),
                      if (lecon.hasPdf) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.picture_as_pdf_rounded, size: 11, color: YekiColors.error),
                        const SizedBox(width: 4),
                        const Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: YekiColors.error)),
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
                  'Lecture',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: YekiColors.white,
                    fontSize: 11,
                  ),
                ),
              )
            else
              Icon(Icons.play_circle_outline_rounded, size: 20, color: YekiColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            border: Border.all(color: YekiColors.white.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: YekiColors.white),
        ),
      ),
    );
  }
}

// ─── IA CHOIX SHEET ──────────────────────────────────────────────────

class _IAChoixSheet extends StatelessWidget {
  final VoidCallback onVoirDiscussion;
  final VoidCallback onPoserPreoccupation;
  final Color courseColor;

  const _IAChoixSheet({
    required this.onVoirDiscussion,
    required this.onPoserPreoccupation,
    required this.courseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: YekiColors.borderLight,
              borderRadius: BorderRadius.circular(8),
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
                  gradient: LinearGradient(
                    colors: [courseColor, courseColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'YIA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: YekiColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Yéki IA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _opt(
            icon: Icons.chat_rounded,
            label: 'Voir la discussion',
            sub: 'Reprendre la conversation IA',
            color: courseColor,
            onTap: onVoirDiscussion,
          ),
          const SizedBox(height: 10),
          _opt(
            icon: Icons.psychology_alt_rounded,
            label: 'Poser une préoccupation',
            sub: 'Expliquer un problème (+ image, + audio)',
            color: YekiColors.purple,
            onTap: onPoserPreoccupation,
          ),
        ],
      ),
    );
  }

  Widget _opt({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: YekiColors.textDark,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 12, color: YekiColors.textMedium),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ─── PRÉOCCUPATION SHEET ────────────────────────────────────────────

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
  final void Function(String texte, File? image, File? audio) onSoumis;

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
  final TextEditingController _ctrl = TextEditingController();
  File? _image;
  File? _audio;
  bool _sending = false;
  bool _isRecording = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _picker = ImagePicker();

  final Map<String, Color> _sc = {
    'lecon': YekiColors.primary,
    'exercice': YekiColors.purple,
    'devoir': YekiColors.warning,
    'libre': YekiColors.success,
  };
  final Map<String, IconData> _si = {
    'lecon': Icons.play_lesson_rounded,
    'exercice': Icons.edit_note_rounded,
    'devoir': Icons.assignment_rounded,
    'libre': Icons.chat_bubble_outline_rounded,
  };
  final Map<String, String> _sl = {
    'lecon': 'Leçon',
    'exercice': 'Exercice',
    'devoir': 'Devoir',
    'libre': 'Libre',
  };

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    try {
      final permission = await _audioRecorder.hasPermission();
      if (mounted) setState(() => _hasPermission = permission);
    } catch (e) {
      if (mounted) setState(() => _hasPermission = false);
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      final permission = await _audioRecorder.hasPermission();
      if (!permission) {
        if (mounted) {
          ErrorHandler.showError(context, 'Permission microphone requise');
        }
        return;
      }
      if (mounted) setState(() => _hasPermission = true);
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/audio_$timestamp.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
      }
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration = _recordingDuration + const Duration(seconds: 1));
        }
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur démarrage: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      if (path != null && mounted) {
        final file = File(path);
        final fileSize = await file.length();
        if (await file.exists() && fileSize > 1024) {
          setState(() {
            _audio = file;
            _isRecording = false;
          });
          ErrorHandler.showSuccess(
            context,
            'Audio enregistré (${(fileSize / 1024).toStringAsFixed(0)} KB)',
          );
        } else {
          setState(() => _isRecording = false);
          ErrorHandler.showError(context, 'Enregistrement trop court');
        }
      } else {
        setState(() => _isRecording = false);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      ErrorHandler.showError(context, 'Erreur arrêt: $e');
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _audioRecorder.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _image = File(picked.path));
  }

  void _removeImage() => setState(() => _image = null);
  void _removeAudio() => setState(() => _audio = null);

  bool get _canSubmit =>
      !_sending &&
      !_isRecording &&
      (_ctrl.text.trim().isNotEmpty || _image != null || _audio != null);

  void _submitForm() {
    if (!_canSubmit) return;
    setState(() => _sending = true);
    widget.onSoumis(_ctrl.text.trim(), _image, _audio);
    setState(() => _sending = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sc = _sc[widget.source] ?? widget.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
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
                  color: YekiColors.borderLight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.source != 'libre' && widget.sourceTitre.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sc.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(_si[widget.source] ?? Icons.link_rounded, color: sc, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_sl[widget.source] ?? widget.source} : ${widget.sourceTitre}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: YekiColors.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: YekiColors.borderLight, width: 1),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 14),
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: widget.isIA
                      ? 'Décrivez votre problème à Yéki IA…'
                      : 'Décrivez votre préoccupation au forum… (optionnel si image ou audio)',
                  hintStyle: const TextStyle(fontSize: 13, color: YekiColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_isRecording && _image == null)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: YekiColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Ajouter une image',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (!_isRecording && _audio == null)
              GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: YekiColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YekiColors.purple.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_rounded, color: YekiColors.purple, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Enregistrer un audio (microphone)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: YekiColors.purple),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isRecording)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YekiColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.error.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(color: YekiColors.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enregistrement • ${_formatDuration(_recordingDuration)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _stopRecording,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: YekiColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Arrêter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: YekiColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _cancelRecording,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: YekiColors.textLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: YekiColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_image != null && !_isRecording) ...[
              const SizedBox(height: 10),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: YekiColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        width: double.infinity,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: YekiColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_audio != null && !_isRecording) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: YekiColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack_rounded, color: YekiColors.purple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio enregistré (${(_audio!.lengthSync() / 1024).toStringAsFixed(0)} KB)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: _removeAudio,
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            YekiButton(
              label: widget.isIA ? 'Envoyer à Yéki IA' : 'Poster dans le Forum',
              icon: widget.isIA ? Icons.send_rounded : Icons.forum_rounded,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}