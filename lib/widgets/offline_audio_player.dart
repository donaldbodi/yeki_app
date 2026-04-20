// lib/widgets/offline_audio_player.dart
// Lecteur audio avec support hors ligne

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:yeki/services/download_manager.dart';
import 'package:yeki/services/offline_service.dart';

class OfflineAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String audioId;
  final String audioTitle;

  const OfflineAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.audioId,
    required this.audioTitle,
  });

  @override
  State<OfflineAudioPlayer> createState() => _OfflineAudioPlayerState();
}

class _OfflineAudioPlayerState extends State<OfflineAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DownloadManager _downloadManager = DownloadManager();
  
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  DownloadStatus _downloadStatus = DownloadStatus.notDownloaded;
  double _downloadProgress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
    _initPlayer();
    _setupListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _checkDownloadStatus() async {
    final status = _downloadManager.getStatus(widget.audioId);
    final isDownloaded = await _downloadManager.isDownloaded(widget.audioId);
    
    setState(() {
      _downloadStatus = status;
      if (isDownloaded) {
        _localPath = OfflineService().getDownloadedFilePath(widget.audioId);
      }
    });
  }

  Future<void> _initPlayer() async {
    setState(() => _isLoading = true);
    
    if (_localPath != null && await File(_localPath!).exists()) {
      await _audioPlayer.setSourceDeviceFile(_localPath!);
    } else {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _downloadAudio() async {
    await _downloadManager.downloadFile(
      url: widget.audioUrl,
      fileId: widget.audioId,
      fileName: '${widget.audioId}.mp3',
      fileType: 'audio',
      onComplete: () async {
        await _checkDownloadStatus();
        await _initPlayer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio téléchargé avec succès'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
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
    
    _downloadManager.getProgress(widget.audioId).listen((progress) {
      if (mounted) {
        setState(() => _downloadProgress = progress);
      }
    });
  }

  Future<void> _deleteDownload() async {
    await _downloadManager.deleteDownloadedFile(widget.audioId);
    await _checkDownloadStatus();
    await _initPlayer();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio supprimé du téléchargement'),
          backgroundColor: Color(0xFFF97316),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4E8), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF135F74).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF135F74),
                    size: 28,
                  ),
                  onPressed: _isLoading ? null : _togglePlay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.audioTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTime(_position),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              _audioPlayer.seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: const Color(0xFF135F74),
                            inactiveColor: const Color(0xFFE0E4E8),
                          ),
                        ),
                        Text(
                          _formatTime(_duration),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_downloadStatus == DownloadStatus.downloaded)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  onPressed: _deleteDownload,
                )
              else if (_downloadManager.canDownload && _downloadStatus == DownloadStatus.notDownloaded)
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  onPressed: _downloadAudio,
                ),
              if (_downloadStatus == DownloadStatus.downloading)
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF135F74)),
                    ),
                  ),
                ),
            ],
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFE0E4E8),
              color: Color(0xFF135F74),
            ),
        ],
      ),
    );
  }
}