import 'package:flutter/widgets.dart';

/// Une destination de navigation — CDC_DESIGN §4.2.
///
/// [routeName] est nul quand aucun écran/route n'existe encore pour
/// cette destination (constat P4.6, acté avec l'utilisateur : la
/// destination reste listée — « aucune destination n'est perdue » — mais
/// n'est pas cliquable tant que l'écran correspondant n'est pas construit
/// dans un ticket ultérieur).
///
/// [badgeKey] identifie QUEL compteur vivant afficher (ex. 'devoirs',
/// 'forum') ; la VALEUR elle-même n'est jamais stockée ici — elle est
/// fournie à l'exécution par l'écran appelant via `YkAdaptiveScaffold
/// .badges`, cohérent avec le reste des composants Yk* (le composant ne
/// lit aucun provider lui-même).
class YkNavDestination {
  const YkNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.routeName,
    this.badgeKey,
    this.inCompactBar = false,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? routeName;
  final String? badgeKey;

  /// Fait partie des 3-5 destinations de la barre du bas en `compact`.
  final bool inCompactBar;

  bool get isWired => routeName != null;

  /// Utilisé par la config Enseignant : `inCompactBar` y dépend du rôle
  /// (position parmi les destinations visibles pour CE rôle), donc pas
  /// figeable en `const` comme pour l'Apprenant — voir
  /// `yk_nav_config_enseignant.dart`.
  YkNavDestination copyWith({bool? inCompactBar}) => YkNavDestination(
    label: label,
    icon: icon,
    selectedIcon: selectedIcon,
    routeName: routeName,
    badgeKey: badgeKey,
    inCompactBar: inCompactBar ?? this.inCompactBar,
  );
}

/// Un groupe de destinations — CDC §4.2 (« groupes de destinations » dans
/// la navbar déployée `large`/`xlarge`). [title] est ignoré en dehors de
/// la navbar déployée (un rail replié 72px n'a pas la place pour un
/// en-tête de section).
class YkNavGroup {
  const YkNavGroup({this.title, required this.destinations});

  final String? title;
  final List<YkNavDestination> destinations;
}
