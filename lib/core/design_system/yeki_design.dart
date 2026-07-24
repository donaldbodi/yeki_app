// lib/core/design/yeki_design.dart
// ═══════════════════════════════════════════════════════════════════
//  YEKI DESIGN SYSTEM — tokens visuels partagés
//  Deux identités : Apprenant (chaud, ludique) / Enseignant (sobre, pro)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── Couleurs communes ──────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kPrimary   = Color(0xFF2884A0);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kTealDark  = Color(0xFF1F5F75);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kTealLight = Color(0xFF39A0C2);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kGold      = Color(0xFFE2A84B);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kAccent    = Color(0xFFFF7F77);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kPurple    = Color.fromARGB(255, 218, 61, 108);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kGreen    = Color.fromARGB(255, 119, 255, 248);

// ── Palette Apprenant ─────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kABg       = Color(0xFFF4F8FC);   // fond général
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kACard     = Colors.white;
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kADark     = Color(0xFF0D1B2A);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kAMuted    = Color(0xFF64748B);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kABorder   = Color(0xFFE8EDF2);

// ── Palette Enseignant ────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kEBg       = Color(0xFFF8FAFB);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kECard     = Colors.white;
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kEDark     = Color(0xFF1A1C1E);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kEMuted    = Color(0xFF6B7280);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kEBorder   = Color(0xFFE5E7EB);
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Color kEInk      = Color(0xFF0D1117);   // dark mode enseignant

// ── Sources Forum ─────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Map<String, Color> kSrcColor = {
  'lecon':    Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir':   Color(0xFFF97316),
  'libre':    Color(0xFF22C55E),
};
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Map<String, IconData> kSrcIcon = {
  'lecon':    Icons.play_lesson_rounded,
  'exercice': Icons.edit_note_rounded,
  'devoir':   Icons.assignment_rounded,
  'libre':    Icons.chat_bubble_outline_rounded,
};
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const Map<String, String> kSrcLabel = {
  'lecon':    'Leçon',
  'exercice': 'Exercice',
  'devoir':   'Devoir',
  'libre':    'Libre',
};

// ── Radius ────────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const double kRadiusSm  = 10;
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const double kRadiusMd  = 16;
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const double kRadiusLg  = 22;
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
const double kRadiusXl  = 28;

// ── Ombres ────────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
List<BoxShadow> kShadowSm = [
  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2)), // 0.05 opacity ≈ 13 alpha
];
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
List<BoxShadow> kShadowMd = [
  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4)), // 0.08 opacity ≈ 20 alpha
];
// ignore: deprecated_member_use_from_same_package
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
List<BoxShadow> kShadowPrimary = [
  BoxShadow(color: kPrimary.withAlpha(64), blurRadius: 20, offset: const Offset(0, 6)), // 0.25 opacity ≈ 64 alpha
];

// ── Helpers ───────────────────────────────────────────────────────
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
String yekiInitials(String nom, String username) {
  final n = nom.isNotEmpty ? nom : username;
  if (n.isEmpty) return '?';
  final parts = n.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return n[0].toUpperCase();
}

// Extension couleur avec .withAlpha() au lieu de .withOpacity()
@Deprecated('Remplacé par lib/core/design/tokens — voir P4.1. Ne pas utiliser dans du nouveau code ; migration écran par écran.')
extension ColorX on Color {
  /// Assombrit la couleur (amount entre 0 et 1)
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Éclaircit la couleur (amount entre 0 et 1)
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  /// Convertit une opacité (0-1) en alpha (0-255)
  Color withOpacityValue(double opacity) {
    return withAlpha((opacity * 255).round().clamp(0, 255));
  }
}