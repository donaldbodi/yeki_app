import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

/// Lecteur audio — CDC_DESIGN §5.3.5 : forme d'onde, vitesse. Utilisé
/// par le forum (messages vocaux).
///
/// **Simplification assumée** : une vraie forme d'onde exige de décoder
/// l'amplitude du fichier audio (hors périmètre raisonnable ici) — la
/// progression est donc représentée par une barre linéaire, pas un
/// tracé d'onde pixel par pixel.
class YkAudioPlayer extends StatefulWidget {
  const YkAudioPlayer({super.key, required this.audioUrl, this.label});

  final String audioUrl;
  final String? label;

  @override
  State<YkAudioPlayer> createState() => _YkAudioPlayerState();
}

class _YkAudioPlayerState extends State<YkAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _speed = 1;

  late final StreamSubscription<Duration> _posSub;
  late final StreamSubscription<Duration> _durSub;
  late final StreamSubscription<PlayerState> _stateSub;

  static const _speeds = [1.0, 1.25, 1.5, 2.0, 0.75];

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _durSub = _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _stateSub = _player.onPlayerStateChanged.listen(
      (s) => setState(() => _isPlaying = s == PlayerState.playing),
    );
  }

  @override
  void dispose() {
    _posSub.cancel();
    _durSub.cancel();
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else if (_position == Duration.zero) {
      await _player.play(UrlSource(widget.audioUrl));
    } else {
      await _player.resume();
    }
  }

  Future<void> _changeSpeed() async {
    final next = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length];
    setState(() => _speed = next);
    await _player.setPlaybackRate(next);
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(YkSpacing.sm),
      decoration: BoxDecoration(
        color: YkColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(YkRadius.md),
      ),
      child: Row(
        children: [
          YkIconButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            label: _isPlaying ? 'Mettre en pause' : 'Lire',
            variant: YkIconButtonVariant.filled,
            onPressed: _toggle,
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(YkRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: YkColors.accent(context),
                    backgroundColor: YkColors.border(context),
                    minHeight: 4,
                  ),
                ),
                Text(
                  '${_format(_position)} / ${_format(_duration)}',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          SizedBox(width: YkSpacing.sm),
          TextButton(
            onPressed: _changeSpeed,
            child: Text(
              '${_speed}x',
              style: YkTypography.label(context).copyWith(color: YkColors.accent(context)),
            ),
          ),
        ],
      ),
    );
  }
}
