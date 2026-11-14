// lib/widgets/forum_style.dart
//
// Couleur/icône/libellé par `source` de question forum (`lecon`,
// `exercice`, `devoir`, `libre`) — extrait de `form_preoccupation_sheet.dart`,
// `forum_page.dart` et `details_question_forum.dart` qui dupliquaient
// chacun leur propre `Map<String, Color>`/`Map<String, IconData>` (règle 1 :
// une seule source pour ces trois écrans).

import 'package:flutter/material.dart';

import 'package:yeki/core/design/tokens/tokens.dart';

Color sourcePreoccupationCouleur(BuildContext context, String source) {
  switch (source) {
    case 'lecon':
      return YkColors.info;
    case 'exercice':
      return YkColors.accent(context);
    case 'devoir':
      return YkColors.warning;
    default:
      return YkColors.success;
  }
}

IconData sourcePreoccupationIcone(String source) {
  switch (source) {
    case 'lecon':
      return Icons.play_lesson_rounded;
    case 'exercice':
      return Icons.edit_note_rounded;
    case 'devoir':
      return Icons.assignment_rounded;
    default:
      return Icons.chat_bubble_outline_rounded;
  }
}

String sourcePreoccupationLabel(String source) {
  switch (source) {
    case 'lecon':
      return "la leçon";
    case 'exercice':
      return "l'exercice";
    case 'devoir':
      return 'le devoir';
    default:
      return 'une question libre';
  }
}

/// Libellé court utilisé dans les puces de filtre / badges (`Leçon`,
/// `Exercice`, `Devoir`, `Libre`) — distinct de
/// [sourcePreoccupationLabel] (« la leçon », utilisé dans une phrase).
String sourceLabelCourt(String source) {
  switch (source) {
    case 'lecon':
      return 'Leçon';
    case 'exercice':
      return 'Exercice';
    case 'devoir':
      return 'Devoir';
    default:
      return 'Libre';
  }
}
