// lib/widgets/compte_rebours.dart
// ════════════════════════════════════════════════════════════════
// COMPTE À REBOURS — GLASSMORPHISM EDITION
// ════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeUp;
  final Color? color;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onTimeUp,
    this.color,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int remaining;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remaining = widget.seconds;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining <= 0) {
        t.cancel();
        widget.onTimeUp();
      } else {
        setState(() => remaining--);
      }
    });
  }

  String get timeFormatted {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  double get progress => remaining / widget.seconds;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? YekiColors.accent;
    final isWarning = remaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône horloge
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_rounded,
              color: isWarning ? YekiColors.error : color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          
          // Affichage du temps
          Text(
            timeFormatted,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isWarning ? YekiColors.error : YekiColors.textDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Barre de progression circulaire
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              backgroundColor: YekiColors.textLight.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? YekiColors.error : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}