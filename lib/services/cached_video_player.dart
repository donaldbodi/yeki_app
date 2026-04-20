// lib/widgets/cached_video_player.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yeki/services/cache_manager.dart';


class CachedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String videoTitle;

  const CachedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  final CacheManager _cacheManager = CacheManager();
  VideoPlayerController? _controller;
  
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isFullscreen = false;
  DownloadStatus _downloadStatus = DownloadStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkDownloadStatus();
    await _initPlayer();
  }

  Future<void> _checkDownloadStatus() async {
    final status = _cacheManager.getStatus(widget.videoId);
    final isCached = await _cacheManager.isCached(widget.videoId);
    
    setState(() {
      _downloadStatus = status;
      if (isCached) {
        _localPath = _cacheManager.getCachedPath(widget.videoId);
      }
    });
  }

  Future<void> _initPlayer() async {
    setState(() => _isLoading = true);
    
    if (_localPath != null && await File(_localPath!).exists()) {
      _controller = VideoPlayerController.file(File(_localPath!));
      await _controller!.initialize();
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
    }
    
    setState(() => _isLoading = false);
    
    _controller!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _downloadVideo() async {
    setState(() => _downloadStatus = DownloadStatus.downloading);
    
    _cacheManager.getProgress(widget.videoId).listen((progress) {
      if (mounted) {
        setState(() => _downloadProgress = progress);
      }
    });
    
    await _cacheManager.downloadFile(
      url: widget.videoUrl,
      fileId: widget.videoId,
      fileName: '${widget.videoId}.mp4',
      fileType: 'video',
      onComplete: () async {
        await _checkDownloadStatus();
        await _initPlayer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vidéo téléchargée avec succès'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _downloadStatus = DownloadStatus.failed);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la vidéo'),
        content: const Text('Voulez-vous supprimer cette vidéo du cache ? Elle sera re-téléchargée à la prochaine lecture.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _cacheManager.deleteDownloadedFile(widget.videoId);
      await _checkDownloadStatus();
      await _initPlayer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo supprimée du cache'),
            backgroundColor: Color(0xFFF97316),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lecteur vidéo
        AspectRatio(
          aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                GestureDetector(
                  onTap: _togglePlay,
                  child: VideoPlayer(_controller!),
                ),
              
              if (_isLoading)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF135F74)),
                  ),
                ),
              
              if (!_isLoading && !_controller!.value.isPlaying)
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
                  ),
                ),
              
              // Barre de progression
              if (!_isLoading)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF135F74),
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
              
              // Bouton plein écran
              if (!_isLoading)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                    onPressed: _toggleFullscreen,
                  ),
                ),
            ],
          ),
        ),
        
        // Boutons de contrôle du cache
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_downloadStatus == DownloadStatus.downloaded)
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  color: Colors.red,
                  onTap: _deleteDownload,
                )
              else if (_downloadStatus == DownloadStatus.downloading)
                _buildProgressButton()
              else if (_downloadStatus == DownloadStatus.failed)
                _buildActionButton(
                  icon: Icons.error_outline,
                  label: 'Réessayer',
                  color: Colors.orange,
                  onTap: _downloadVideo,
                )
              else
                _buildActionButton(
                  icon: Icons.download_outlined,
                  label: 'Télécharger',
                  color: const Color(0xFF135F74),
                  onTap: _downloadVideo,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF135F74).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF135F74).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 2,
              color: const Color(0xFF135F74),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_downloadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 11, color: Color(0xFF135F74), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}