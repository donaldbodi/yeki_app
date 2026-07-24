import 'dart:async';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Format d'affichage de [YkCountdown] — P8.3.
enum YkCountdownFormat {
  /// `mm:ss` — minuteur d'une session active (examen/devoir/olympiade en
  /// cours). Défaut, comportement inchangé depuis la création (CDC §5.3.4).
  compact,

  /// `Xj Xh Xmin` — compte à rebours vers un instant FUTUR, potentiellement
  /// à plusieurs jours (ex. début d'une olympiade). Les seuils d'urgence
  /// n'ont pas de sens sur cette échelle (25 % d'une semaine reste
  /// « dans 2 jours », pas urgent) : la couleur reste neutre dans ce mode.
  verbose,
}

/// Compte à rebours — CDC_DESIGN §5.3.4. Remplace `compte_rebours.dart`
/// (supprimé, 0 usage). Seuils **configurables** (règle 3 : 25 %/10 %
/// sont les valeurs par défaut du CDC, pas des constantes figées) ;
/// sémantique vocale via `Semantics(liveRegion: true)`.
///
/// [format] : `compact` (défaut, minuteur de session active) ou
/// `verbose` (P8.3 : compte à rebours vers un début d'olympiade, jours/
/// heures/minutes) — même composant plutôt qu'un second widget parallèle
/// (règle 1), le ticket nommant `YkCountdown` explicitement.
class YkCountdown extends StatefulWidget {
  const YkCountdown({
    super.key,
    required this.duration,
    required this.onExpired,
    this.warningThreshold = 0.25,
    this.errorThreshold = 0.10,
    this.format = YkCountdownFormat.compact,
  });

  final Duration duration;
  final VoidCallback onExpired;

  /// Fraction du temps total restant en dessous de laquelle la couleur
  /// passe à `warning` (défaut CDC : 25 %). Ignoré en mode `verbose`.
  final double warningThreshold;

  /// Fraction du temps total restant en dessous de laquelle la couleur
  /// passe à `error` (défaut CDC : 10 %). Ignoré en mode `verbose`.
  final double errorThreshold;

  final YkCountdownFormat format;

  @override
  State<YkCountdown> createState() => _YkCountdownState();
}

class _YkCountdownState extends State<YkCountdown> {
  late Duration _remaining = widget.duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (!mounted) return;
    final next = _remaining - const Duration(seconds: 1);
    setState(() => _remaining = next.isNegative ? Duration.zero : next);
    if (_remaining == Duration.zero) {
      timer.cancel();
      widget.onExpired();
    }
  }

  double get _fraction =>
      widget.duration.inSeconds == 0 ? 0 : _remaining.inSeconds / widget.duration.inSeconds;

  Color _color(BuildContext context) {
    // Seuils d'urgence dénués de sens sur une échelle de plusieurs jours
    // (mode verbose) — toujours la couleur neutre dans ce cas.
    if (widget.format == YkCountdownFormat.verbose) return YkColors.accent(context);
    if (_fraction <= widget.errorThreshold) return YkColors.error;
    if (_fraction <= widget.warningThreshold) return YkColors.warning;
    return YkColors.accent(context);
  }

  String get _formatted => switch (widget.format) {
    YkCountdownFormat.compact => _formattedCompact,
    YkCountdownFormat.verbose => _formattedVerbose,
  };

  String get _formattedCompact {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// `Xj Xh Xmin` — tronqué au(x) plus grand(s) niveau(x) pertinent(s)
  /// (jours omis si < 1 jour, heures omises si < 1 heure).
  String get _formattedVerbose {
    final jours = _remaining.inDays;
    final heures = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    if (jours > 0) return '${jours}j ${heures}h ${minutes}min';
    if (heures > 0) return '${heures}h ${minutes}min';
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Semantics(
      liveRegion: true,
      label: 'Temps restant : $_formatted',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(YkRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: color),
            SizedBox(width: YkSpacing.xxs),
            Text(_formatted, style: YkTypography.label(context).copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
