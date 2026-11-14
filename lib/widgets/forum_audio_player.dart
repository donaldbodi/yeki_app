// lib/widgets/forum_audio_player.dart
//
// Extrait en P10.5 : défini à l'identique dans `forum_page.dart` ET
// `details_question_forum.dart` (copie exacte, règle 1 — une seule
// source désormais).

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/utils/error_handler.dart';

class ForumAudioPlayer extends StatefulWidget {
  const ForumAudioPlayer({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<ForumAudioPlayer> createState() => _ForumAudioPlayerState();
}

class _ForumAudioPlayerState extends State<ForumAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      });
      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });
    } catch (e) {
      debugPrint('Erreur initialisation audio: $e');
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          setState(() => _isLoading = true);
          try {
            await _audioPlayer.setSourceUrl(widget.audioUrl);
          } catch (e) {
            debugPrint('Erreur setSourceUrl: $e');
            if (mounted) ErrorHandler.showError(context, 'Erreur de chargement audio');
            setState(() => _isLoading = false);
            return;
          }
          setState(() => _isLoading = false);
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Erreur lecture audio: $e');
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur de lecture audio');
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = YkColors.accent(context);
    return Row(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _togglePlay,
          child: _isLoading
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: accent,
                  size: 32,
                ),
        ),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0.0,
                backgroundColor: YkColors.border(context),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 3,
              ),
              SizedBox(height: YkSpacing.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
