// lib/utils/cours_icons.dart
//
// Source unique des icônes de cours (`Cours.icon_name`) — remplace 3
// listes dupliquées et divergentes trouvées dans `creer_cours_sheet.dart`
// (`_icones`, vocabulaire `name`), `modifier_cours_sheet.dart`
// (`_iconesCours`, vocabulaire `nom`, 2 icônes en plus) et
// `secondaire_dashboard_page.dart` (`_iconePourCours`, une table de rendu
// à part ne reconnaissant même pas la moitié des noms réels produits par
// le formulaire de création — un mismatch confirmé, cause du "l'icône ne
// s'affiche pas correctement ailleurs"). Même précédent que
// `color_utils.dart` (extrait pour la même raison en P11.6).

import 'package:flutter/material.dart';

class CoursIcon {
  const CoursIcon({required this.name, required this.icon, required this.label});

  /// Valeur stockée dans `Cours.icon_name` — stable, ne jamais renommer un
  /// nom existant (des cours réels en base y font déjà référence).
  final String name;
  final IconData icon;
  final String label;
}

const List<CoursIcon> coursIcons = [
  CoursIcon(name: 'school', icon: Icons.school, label: 'École'),
  CoursIcon(name: 'book', icon: Icons.book, label: 'Livre'),
  CoursIcon(name: 'calculate', icon: Icons.calculate, label: 'Maths'),
  CoursIcon(name: 'science', icon: Icons.science, label: 'Sciences'),
  CoursIcon(name: 'language', icon: Icons.language, label: 'Langue'),
  CoursIcon(name: 'computer', icon: Icons.computer, label: 'Info'),
  CoursIcon(name: 'history_edu', icon: Icons.history_edu, label: 'Histoire'),
  CoursIcon(name: 'psychology', icon: Icons.psychology, label: 'Philo'),
  CoursIcon(name: 'bar_chart', icon: Icons.bar_chart, label: 'Stats'),
  CoursIcon(name: 'biotech', icon: Icons.biotech, label: 'Bio'),
  CoursIcon(name: 'music_note', icon: Icons.music_note, label: 'Musique'),
  CoursIcon(name: 'sports_soccer', icon: Icons.sports_soccer, label: 'Sport'),
  CoursIcon(name: 'palette', icon: Icons.palette, label: 'Art'),
  CoursIcon(name: 'engineering', icon: Icons.engineering, label: 'Ingé'),
  CoursIcon(name: 'medical_services', icon: Icons.medical_services, label: 'Médecine'),
  CoursIcon(name: 'architecture', icon: Icons.architecture, label: 'Architecture'),
  CoursIcon(name: 'eco', icon: Icons.eco, label: 'Écologie'),
  // Ajoutés (demande explicite : plus d'icônes éducatives) — vocabulaire
  // déjà utilisé ailleurs dans le projet (`cursus_page.dart`), pour rester
  // cohérent.
  CoursIcon(name: 'gavel', icon: Icons.gavel, label: 'Droit'),
  CoursIcon(name: 'terminal', icon: Icons.terminal, label: 'Programmation'),
  CoursIcon(name: 'menu_book', icon: Icons.menu_book, label: 'Lecture'),
  CoursIcon(name: 'quiz', icon: Icons.quiz, label: 'Évaluation'),
  CoursIcon(name: 'emoji_events', icon: Icons.emoji_events, label: 'Concours'),
];

/// Icône correspondant à un `icon_name` stocké — repli sur l'icône École
/// si le nom est absent/inconnu (même comportement que les 3 anciennes
/// tables qu'elle remplace).
IconData iconePourNom(String? nom) {
  return coursIcons.firstWhere((i) => i.name == nom, orElse: () => coursIcons.first).icon;
}
