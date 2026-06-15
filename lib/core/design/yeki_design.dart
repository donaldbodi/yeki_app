// lib/core/design/yeki_design.dart
// ═══════════════════════════════════════════════════════════════════
//  YEKI DESIGN SYSTEM — tokens visuels partagés
//  Deux identités : Apprenant (chaud, ludique) / Enseignant (sobre, pro)
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ── Couleurs communes ──────────────────────────────────────────────
const Color kPrimary   = Color(0xFF2884A0);
const Color kTealDark  = Color(0xFF1F5F75);
const Color kTealLight = Color(0xFF39A0C2);
const Color kGold      = Color(0xFFE2A84B);
const Color kAccent    = Color(0xFFFF7F77);

// ── Palette Apprenant ─────────────────────────────────────────────
const Color kABg       = Color(0xFFF4F8FC);   // fond général
const Color kACard     = Colors.white;
const Color kADark     = Color(0xFF0D1B2A);
const Color kAMuted    = Color(0xFF64748B);
const Color kABorder   = Color(0xFFE8EDF2);

// ── Palette Enseignant ────────────────────────────────────────────
const Color kEBg       = Color(0xFFF8FAFB);
const Color kECard     = Colors.white;
const Color kEDark     = Color(0xFF1A1C1E);
const Color kEMuted    = Color(0xFF6B7280);
const Color kEBorder   = Color(0xFFE5E7EB);
const Color kEInk      = Color(0xFF0D1117);   // dark mode enseignant

// ── Sources Forum ─────────────────────────────────────────────────
const Map<String, Color> kSrcColor = {
  'lecon':    Color(0xFF3B82F6),
  'exercice': Color(0xFFA855F7),
  'devoir':   Color(0xFFF97316),
  'libre':    Color(0xFF22C55E),
};
const Map<String, IconData> kSrcIcon = {
  'lecon':    Icons.play_lesson_rounded,
  'exercice': Icons.edit_note_rounded,
  'devoir':   Icons.assignment_rounded,
  'libre':    Icons.chat_bubble_outline_rounded,
};
const Map<String, String> kSrcLabel = {
  'lecon':    'Leçon',
  'exercice': 'Exercice',
  'devoir':   'Devoir',
  'libre':    'Libre',
};

// ── Radius ────────────────────────────────────────────────────────
const double kRadiusSm  = 10;
const double kRadiusMd  = 16;
const double kRadiusLg  = 22;
const double kRadiusXl  = 28;

// ── Ombres ────────────────────────────────────────────────────────
List<BoxShadow> kShadowSm = [
  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2)), // 0.05 opacity ≈ 13 alpha
];
List<BoxShadow> kShadowMd = [
  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4)), // 0.08 opacity ≈ 20 alpha
];
List<BoxShadow> kShadowPrimary = [
  BoxShadow(color: kPrimary.withAlpha(64), blurRadius: 20, offset: const Offset(0, 6)), // 0.25 opacity ≈ 64 alpha
];

// ── Helpers ───────────────────────────────────────────────────────
String yekiInitials(String nom, String username) {
  final n = nom.isNotEmpty ? nom : username;
  if (n.isEmpty) return '?';
  final parts = n.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return n[0].toUpperCase();
}

// Extension couleur avec .withAlpha() au lieu de .withOpacity()
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