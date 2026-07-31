// lib/utils/color_utils.dart
//
// Analyse tolérante d'une couleur hexadécimale API (`#RRGGBB`) — extrait
// de `dashboard_skeleton.dart` (P11.5) pour être réutilisable en dehors de
// `lib/views/pages/enseignants/` (P11.6, `creer_cours_sheet.dart`) sans
// dépendance croisée artificielle entre `lib/widgets/` et cet écran.

import 'package:flutter/material.dart';

Color couleurDepuisHex(String? hex, Color repli) {
  if (hex == null || hex.isEmpty) return repli;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return repli;
  }
}
