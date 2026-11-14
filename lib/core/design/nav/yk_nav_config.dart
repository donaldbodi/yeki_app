import 'yk_nav_config_apprenant.dart';
import 'yk_nav_config_enseignant.dart';
import 'yk_nav_destination.dart';

/// Façade — CDC_DESIGN §4.2 : « un composant qui reçoit une liste de
/// destinations, et deux fichiers de configuration qui décrivent ces
/// listes ». `YkAdaptiveScaffold` ne connaît que [YkNavConfig.forRole] ;
/// toute la différence entre les interfaces Apprenant et Enseignant vit
/// dans les deux fichiers `yk_nav_config_apprenant.dart`/
/// `yk_nav_config_enseignant.dart`, jamais dans le composant lui-même.
class YkNavConfig {
  YkNavConfig._();

  static List<YkNavGroup> forRole(String role) =>
      role == 'apprenant' ? apprenantNavGroups : enseignantNavGroups(role);
}
