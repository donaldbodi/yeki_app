import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_chip.dart';

class YkVideoChapter {
  const YkVideoChapter({required this.label, required this.position});
  final String label;
  final Duration position;
}

/// Lecteur vidéo — CDC_DESIGN §5.3.5 : chapitres, vitesse, plein écran,
/// sous-titres, reprise, indicateur hors-ligne. Bâti sur `chewie` (déjà
/// en dépendance) — vitesse/plein écran/contrôles sont natifs au
/// paquet, pas réécrits à la main.
class YkVideoPlayer extends StatefulWidget {
  const YkVideoPlayer({
    super.key,
    required this.videoUrl,
    this.startAt,
    this.chapters = const [],
    this.isOffline = false,
    this.onPositionChanged,
    this.fillScreen = false,
  });

  final String videoUrl;

  /// Position de reprise (le caller la persiste et la fournit au retour
  /// sur l'écran).
  final Duration? startAt;
  final List<YkVideoChapter> chapters;
  final bool isOffline;

  /// P17.17 : plein écran « style TikTok » (`detail_lecon_page.dart`) —
  /// remplit tout l'espace disponible en `BoxFit.cover` (rognée si besoin)
  /// au lieu de se cantonner à son `AspectRatio` natif. Défaut `false` :
  /// comportement inchangé pour tout autre appelant (vitrine du design
  /// system, tout futur lecteur encadré classique).
  final bool fillScreen;

  /// Appelé périodiquement — l'écran appelant décide s'il persiste cette
  /// position pour la reprise.
  final ValueChanged<Duration>? onPositionChanged;

  @override
  State<YkVideoPlayer> createState() => _YkVideoPlayerState();
}

class _YkVideoPlayerState extends State<YkVideoPlayer> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    if (widget.onPositionChanged != null) {
      _videoController.addListener(_reportPosition);
    }
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoInitialize: true,
          startAt: widget.startAt,
          allowPlaybackSpeedChanging: true,
        );
      });
    });
  }

  void _reportPosition() => widget.onPositionChanged?.call(_videoController.value.position);

  @override
  void dispose() {
    _videoController.removeListener(_reportPosition);
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final video = widget.fillScreen
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          );

    if (widget.fillScreen) {
      // Plein écran : pas de `Column`/chapitres sous la vidéo (aucun
      // espace pour eux dans un flux immersif) — la vidéo occupe la
      // totalité de l'espace donné par l'appelant.
      return Stack(
        fit: StackFit.expand,
        children: [
          video,
          if (widget.isOffline) _buildBadgeHorsLigne(context),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            video,
            if (widget.isOffline) _buildBadgeHorsLigne(context),
          ],
        ),
        if (widget.chapters.isNotEmpty) ...[
          SizedBox(height: YkSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final chapter in widget.chapters)
                  Padding(
                    padding: EdgeInsets.only(right: YkSpacing.xs),
                    child: YkChip(
                      label: chapter.label,
                      variant: YkChipVariant.assist,
                      onPressed: () => _videoController.seekTo(chapter.position),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadgeHorsLigne(BuildContext context) {
    return Positioned(
      top: YkSpacing.xs,
      left: YkSpacing.xs,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(YkRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 12, color: Colors.white),
            SizedBox(width: YkSpacing.xxs),
            Text('Hors ligne', style: YkTypography.caption(context).copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
