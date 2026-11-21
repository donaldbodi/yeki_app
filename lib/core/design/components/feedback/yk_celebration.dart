import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../containers/yk_card.dart';

/// Célébration — CDC_DESIGN §5.3.6 : confettis + son optionnel +
/// statistique mise en avant. Exigence explicite : « si l'apprenant
/// gagne en rang dans le département, il devra être informé par des
/// félicitations et l'affichage du rang actuel ».
class YkCelebration extends StatefulWidget {
  const YkCelebration({
    super.key,
    required this.title,
    required this.statLabel,
    required this.statValue,
    this.soundAssetPath,
    this.onDismiss,
  });

  final String title;
  final String statLabel;
  final String statValue;

  /// Chemin d'asset audio optionnel (ex. `'sounds/celebration.mp3'`).
  final String? soundAssetPath;
  final VoidCallback? onDismiss;

  @override
  State<YkCelebration> createState() => _YkCelebrationState();
}

class _YkCelebrationState extends State<YkCelebration> {
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController.play();
    final sound = widget.soundAssetPath;
    if (sound != null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.play(AssetSource(sound));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: YkSpacing.xxl),
          child: Semantics(
            liveRegion: true,
            label: '${widget.title}. ${widget.statLabel} : ${widget.statValue}',
            child: YkCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 48, color: YkColors.warning),
                  SizedBox(height: YkSpacing.sm),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
                  ),
                  SizedBox(height: YkSpacing.xs),
                  Text(
                    widget.statValue,
                    style: YkTypography.h2(context).copyWith(color: YkColors.accent(context)),
                  ),
                  Text(
                    widget.statLabel,
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                  if (widget.onDismiss != null) ...[
                    SizedBox(height: YkSpacing.md),
                    YkButton(label: 'Continuer', onPressed: widget.onDismiss),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
