# AUDIT_FRONTEND — P3.1

Audit exhaustif du frontend Flutter (`lib/`), **avant toute modification**
(tâche purement documentaire, aucun fichier de code touché). Tous les
comptages ci-dessous sont **vérifiés par exécution réelle** de `rg`/`grep`
au moment de la rédaction (2026-07-18), pas estimés. Quand le chiffre
donné par la consigne diverge du chiffre vérifié, les deux sont indiqués
explicitement — jamais de correction silencieuse.

## Synthèse (consigne vs vérifié)

| Métrique | Consigne | Vérifié | Écart |
|---|---|---|---|
| Import `core/theme/yeki_design_system.dart` | 21 | **23** | +2 (import relatif non détecté par un grep naïf) |
| Import `core/theme/app_theme.dart` | 21 | **22** | +1 (+1 import mort commenté, exclu) |
| Import `core/design_system/yeki_design_system.dart` | 7 | **7** | exact |
| Import `core/theme/yeki_design_extension.dart` | 2 | **2** | exact |
| Import `core/design_system/yeki_design.dart` | 1 | **1** | exact |
| `Color(0x…)` hors thème | 169 | **206** | +37 (21 fichiers non listés par la consigne) |
| `setState(` | 575 | **610** | +35 |
| Fichiers `http.*` direct | 48 | **53** (57 en comptant `http.Request`/`MultipartRequest`) | +5 à +9 |
| `Navigator.push` | 81 | **65** (77 toutes variantes confondues) | −16 à −4, écart non expliqué |
| `GoRouter` | 0 | **0** | exact (mais dépendance déclarée, jamais utilisée) |
| `Riverpod` | 0 | **0** | exact (mais dépendance déclarée, jamais utilisée) |
| `Semantics` | 0 | **0** | exact |
| `PopScope` | 1 (composer_devoir_page.dart) | **1**, confirmé au même endroit | exact |
| Classes dans devoirs_cours_page.dart | jusqu'à 14 | **14** (10 widgets + 4 classes de données) | exact |

---

## 1. Les systèmes de design concurrents

### 1.1 Fichiers trouvés — 6, pas 5

La consigne en listait 5 ; la recherche en a trouvé un **6ᵉ, non signalé**,
totalement mort.

| # | Fichier | Importeurs (vérifié) | Classe de tokens |
|---|---|---|---|
| 1 | `lib/core/theme/yeki_design_system.dart` | **23** | `YekiColors` |
| 2 | `lib/core/theme/app_theme.dart` | **22** | `YekiColors` |
| 3 | `lib/core/design_system/yeki_design_system.dart` | **7** | `YekiColors` |
| 4 | `lib/core/theme/yeki_design_extension.dart` | **2** | `YekiRoleColors`/`YekiStateColors` (importe `YekiColors` du fichier 1) |
| 5 | `lib/core/design_system/yeki_design.dart` | **1** | constantes top-level `k*` (pas de classe `YekiColors`) |
| **6 (nouveau)** | `lib/core/theme/yeki_theme.dart` | **0** | `class YColors` (nom différent) — mort |

Confirmation du point le plus important de la consigne : **les fichiers 1
et 3 portent le même nom de fichier** (`yeki_design_system.dart`) à deux
chemins différents. Un `import 'package:yeki/.../yeki_design_system.dart'`
ne permet pas de savoir lequel est visé sans lire le chemin complet.

Piège méthodologique confirmé en creusant les comptages : un grep sur le
chemin complet **rate les imports relatifs**. `yeki_design_extension.dart`
importe son voisin via `import 'yeki_design_system.dart';` (sans chemin
`core/theme/`) — ce qui résout, par position sur le disque, vers le
fichier 1, pas le fichier 3. C'est cet import relatif qui porte le compte
du fichier 1 de 22 à 23.

Le fichier 3 revendique lui-même, dans son commentaire d'en-tête,
remplacer les fichiers 1 et 4 plus un troisième (`yeki_glass_kit.dart`,
qui n'existe plus sur le disque) — la migration vers ce fichier 3 a donc
été commencée puis abandonnée en cours de route : les fichiers qu'il
devait remplacer sont toujours ceux les plus largement importés.

### 1.2 Liste complète des importeurs

**Fichier 1 — `core/theme/yeki_design_system.dart` (23)**
```
lib/widgets/yeki_app_bar.dart
lib/widgets/wallet_page.dart
lib/widgets/compte_rebours.dart
lib/views/auth/register_page.dart
lib/views/auth/forgot_password_flow.dart
lib/views/auth/login_page.dart
lib/views/pages/onboarding.dart
lib/utils/error_handler.dart
lib/views/pages/apprenants/concours_pages.dart
lib/views/pages/apprenants/concours_detail_page.dart
lib/views/pages/enseignants/secondaire_dashboard_page.dart
lib/views/pages/apprenants/cursus_page.dart
lib/views/pages/apprenants/detail_lecon_page.dart
lib/views/pages/enseignants/interface_enseignant_page.dart
lib/views/pages/apprenants/cours_detail_page.dart
lib/views/pages/apprenants/dasboard.dart
lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
lib/views/pages/apprenants/devoirs_page.dart
lib/views/pages/apprenants/formations_pages.dart
lib/views/pages/apprenants/formation_detail_page.dart
lib/views/pages/enseignants/admin_general_page.dart
lib/views/pages/apprenants/olympiades_page.dart
lib/core/theme/yeki_design_extension.dart   (import relatif 'yeki_design_system.dart')
```

**Fichier 2 — `core/theme/app_theme.dart` (22)**
```
lib/widgets/creer_cours_sheet.dart
lib/views/pages/shared/profil_page.dart
lib/views/pages/shared/notifications_page.dart
lib/views/pages/apprenants/classement_departement_page.dart
lib/views/pages/apprenants/yeki_ia_chat_page.dart
lib/views/pages/enseignants/principal_dashboard_page.dart
lib/views/pages/apprenants/sheet_inscription.dart
lib/views/pages/enseignants/historique_page.dart
lib/services/cached_video_player.dart
lib/views/pages/apprenants/settings_page.dart
lib/views/pages/enseignants/gestion_demandes_page.dart
lib/views/pages/apprenants/details_question_forum.dart
lib/views/pages/apprenants/repetiteurs_page.dart
lib/views/pages/apprenants/exercices_cours.dart
lib/views/pages/enseignants/detail_departement_page.dart
lib/views/pages/apprenants/paiement_page.dart
lib/views/pages/enseignants/detail_cours_enseignant.dart
lib/views/pages/apprenants/edit_profil_page.dart
lib/views/pages/apprenants/devoirs_cours_page.dart
lib/views/pages/enseignants/cadre_dashboard_page.dart
lib/views/pages/apprenants/lecture_lecon_page.dart
lib/views/pages/apprenants/forum_page.dart
```
Note : `lib/views/pages/apprenants/lecons_cours.dart:15` contient
`//import 'package:yeki/core/theme/app_theme.dart';` — import **mort,
commenté**, exclu du compte (preuve d'une tentative de migration
antérieure abandonnée).

**Fichier 3 — `core/design_system/yeki_design_system.dart` (7)**
```
lib/widgets/creer_olympiade_sheet.dart
lib/views/pages/apprenants/classement_olympiade.dart
lib/views/pages/apprenants/composer_devoir_page.dart
lib/views/pages/apprenants/olympiade_inscription_page.dart
lib/views/pages/apprenants/passer_exercice.dart
lib/views/pages/apprenants/resultat_devoir_page.dart
lib/views/pages/apprenants/resultat_exercice_page.dart
```

**Fichier 4 — `core/theme/yeki_design_extension.dart` (2)**
```
lib/views/pages/enseignants/admin_general_page.dart
lib/views/pages/enseignants/interface_enseignant_page.dart
```

**Fichier 5 — `core/design_system/yeki_design.dart` (1)**
```
lib/widgets/yeki_fabs.dart
```

**Fichier 6 — `core/theme/yeki_theme.dart` (0)** : aucun importeur trouvé
nulle part dans `lib/`. Définit `YColors`, `YText`, `YShadow`, `YRadius`,
`YGradient`, et des widgets `YButton`/`YChip`/`YCard`/`YAvatar`/
`YStatusBadge`/`YSliverHeader`/`YSkeleton` — tout un mini design system
entier, jamais branché.

### 1.3 Tokens `YekiColors` par fichier

Seuls les fichiers 1, 2 et 3 définissent une classe nommée `YekiColors`
(`rg -n "class YekiColors" lib` confirme exactement 3 résultats — pas de
7ᵉ fichier caché). Le fichier 4 importe celle du fichier 1 sans en
redéfinir une. Le fichier 5 n'a pas de classe `YekiColors` du tout —
seulement des constantes top-level préfixées `k`.

**A) `core/theme/app_theme.dart` (`YekiColors`, L12-42)**
```
primaryDark=0xFF135F74   primaryLight=0xFF2884A0   accent=0xFFFF6B00
gold=0xFFC5A059          purple=0xFF8B5CF6         textDark=0xFF1A1C1E
textMedium=0xFF5A5C5E    textLight=0xFF8A8C8E      backgroundLight=0xFFF8FAFC
backgroundAlt=0xFFF1F5F9 white=0xFFFFFFFF          black=0xFF000000
success=0xFF10B981       error=0xFFEF4444          warning=0xFFF59E0B
info=0xFF3B82F6          borderLight=0xFFE0E4E8    borderMedium=0xFFD0D4D8
borderDark=0xFFC0C4C8    primaryGradient=LinearGradient([primaryDark, primaryLight])
```

**B) `core/theme/yeki_design_system.dart` (`YekiColors`, L89-112)**
```
primary=0xFF2884A0       purple=0xFFDA3D6C (via Color.fromARGB)  primaryDark=0xFF1F5F75
primaryLight=0xFF39A0C2  info=0xFF3B82F6   accent=0xFFFF7F77     gold=0xFFE2A84B
success=0xFF10B981       warning=0xFFF97316  error=0xFFDA3D6C    bgDark=0xFF0D1B2A
bgLight=0xFFF4F8FC       borderLight=0xFFF4F8FC   textDark=0xFF1E293B
textMedium=0xFF64748B    textLight=0xFFCBD5E1     white=Colors.white
glassBgLight=Colors.white.withAlpha(140)  glassBorderLight=Colors.white.withAlpha(180)
```
Anomalie interne (pas une collision inter-fichiers) : `purple` et `error`
résolvent tous les deux à `0xFFDA3D6C` dans ce même fichier — probable
copier-coller.

**C) `core/design_system/yeki_design_system.dart` (`YekiColors`, L35-72)**
```
primary=0xFF1A5276       primaryLight=0xFF2E7DA6   primaryDark=0xFF0F3B57
bgLight=0xFFF8FAFC       surfaceLight=Colors.white  textDark=0xFF0F172A
textMedium=0xFF475569    textFaint=0xFF94A3B8       borderLight=0xFFE2E8F0
bgDark=0xFF0F172A        surfaceDark=0xFF16213A     textOnDark=0xFFF1F5F9
textOnDarkMedium=0xFFA3B0C2  borderDark=0xFF2A3A55   success=0xFF10B981
warning=0xFFF59E0B       error=0xFFDC2626           info=0xFF2563EB
gold=0xFFCA8A04          white=Colors.white (alias)  backgroundLight=bgLight (alias)
textLight=textFaint (alias)  purple=0xFF9333EA       accent=0xFF10B981
```
Anomalie interne : `accent` == `success` (`0xFF10B981`) dans ce même
fichier — probable copier-coller également.

### 1.4 Collisions confirmées (même nom, valeur différente selon le fichier importé)

| Token | app_theme.dart | theme/yeki_design_system.dart | design_system/yeki_design_system.dart |
|---|---|---|---|
| `primary` | *(absent)* | `0xFF2884A0` | `0xFF1A5276` |
| `primaryDark` | `0xFF135F74` | `0xFF1F5F75` | `0xFF0F3B57` |
| `primaryLight` | `0xFF2884A0` | `0xFF39A0C2` | `0xFF2E7DA6` |
| `accent` | `0xFFFF6B00` | `0xFFFF7F77` | `0xFF10B981` |
| `gold` | `0xFFC5A059` | `0xFFE2A84B` | `0xFFCA8A04` |
| `purple` | `0xFF8B5CF6` | `0xFFDA3D6C` | `0xFF9333EA` |
| `textDark` | `0xFF1A1C1E` | `0xFF1E293B` | `0xFF0F172A` |
| `textMedium` | `0xFF5A5C5E` | `0xFF64748B` | `0xFF475569` |
| `textLight` | `0xFF8A8C8E` | `0xFFCBD5E1` | `0xFF94A3B8` |
| `error` | `0xFFEF4444` | `0xFFDA3D6C` | `0xFFDC2626` |
| `borderLight` | `0xFFE0E4E8` | `0xFFF4F8FC` | `0xFFE2E8F0` |

11 tokens en collision confirmée, sur des fichiers importés respectivement
22, 23 et 7 fois. `YekiColors.primaryDark` résout donc à 3 bleus visibles
différents (`#135F74`, `#1F5F75`, `#0F3B57`) selon le fichier importé par
la page en cours d'édition — un risque d'incohérence visuelle réel, déjà
matérialisé, pas hypothétique.

Tokens qui NE collisionnent PAS (même valeur partout où ils existent) :
`success` (`0xFF10B981` dans les 3), `white` (`Colors.white`/`0xFFFFFFFF`
dans les 3).

### 1.5 `main.dart` — le seul thème réellement appliqué

`lib/main.dart` construit son propre `ThemeData` en ligne (L37-65) :
```dart
final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF135F74),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    accentColor: const Color(0xFFC5A059),
    backgroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(...),
  inputDecorationTheme: InputDecorationTheme(...),
  textTheme: const TextTheme(...),
);
```
`MaterialApp(theme: appTheme, ...)` (L106) confirme que c'est bien
**celui-ci, et lui seul**, qui est appliqué au runtime.

`main.dart` **n'importe aucun des 6 fichiers** listés ci-dessus. Ses
valeurs (`0xFF135F74`, `0xFFC5A059`) sont identiques à celles de
`YekiColors.primaryDark`/`gold` dans `app_theme.dart` — copiées à la main,
pas importées. Le splash screen (`_SplashScreen`, L152-167) hardcode en
plus `0xFF0D1B2A`/`0xFF2884A0`, qui coïncident avec `kADark`/`kPrimary` du
fichier 5 — encore par copier-coller, pas par import.

---

## 2. 206 occurrences de `Color(0x…)` hors thème (pas 169)

Comptage : `rg -c "Color\(0x" lib -g "*.dart"`, total brut = 324 dans tout
`lib/` ; 118 à l'intérieur des 6 fichiers de thème (légitime, c'est leur
rôle) ; **206 hors thème** = le chiffre à comparer aux 169 de la consigne.

Les 8 fichiers nommés par la consigne sont **tous exacts individuellement**
(somme = 126) — l'écart de +37 vient entièrement de **21 fichiers non
listés par la consigne**, totalisant 80 occurrences supplémentaires.

### 2.1 Les 8 fichiers cités par la consigne — confirmés exacts

#### `views/pages/enseignants/historique_page.dart` (34)
Mappe chaque type d'événement du fil d'activité à une couleur d'icône.

| Ligne | Hex | Usage | Token le plus proche |
|---|---|---|---|
| 17 | `0xFF2E7D32` | icône « cours créé » | aucun exact (sémantique = success) |
| 18 | `0xFF1565C0` | icône « cours modifié » | aucun exact (sémantique = info) |
| 19 | `0xFFC62828` | icône « cours supprimé » | aucun exact (sémantique = error) |
| 20 | `0xFFE65100` | icône « enseignant assigné » | aucun exact (sémantique = warning) |
| 21 | `0xFFE65100` | icône « enseignant changé » | aucun exact |
| 22 | `0xFF00838F` | icône « secondaire ajouté » | aucun exact |
| 23 | `0xFFAD1457` | icône « secondaire retiré » | aucun exact |
| 24 | `0xFF6A1B9A` | icône « module créé » | aucun exact |
| 25 | `0xFF4527A0` | icône « module modifié » | aucun exact |
| 26 | `0xFFC62828` | icône « module supprimé » | aucun exact |
| 27 | `0xFF00695C` | icône « leçon créée » | aucun exact |
| 28 | `0xFF00695C` | icône « leçon modifiée » | aucun exact |
| 29 | `0xFFC62828` | icône « leçon supprimée » | aucun exact |
| 30 | `0xFF558B2F` | icône « devoir créé » | aucun exact |
| 31 | `0xFF558B2F` | icône « devoir modifié » | aucun exact |
| 32 | `0xFF558B2F` | icône « devoir noté » | aucun exact |
| 33 | `0xFF283593` | icône « exercice créé » | aucun exact |
| 34 | `0xFF283593` | icône « question ajoutée » | aucun exact |
| 35 | `0xFFBF360C` | icône « olympiade créée » | aucun exact |
| 36 | `0xFFBF360C` | icône « olympiade close » | aucun exact |
| 37 | `0xFFBF360C` | icône « classement calculé » | aucun exact |
| 38 | `0xFF00695C` | icône « département créé » | aucun exact |
| 39 | `0xFF006064` | icône « cadre assigné » | aucun exact |
| 40 | `0xFF2E7D32` | icône « soumission notée » | aucun exact |
| 280 | `0xFF1A5276` | dégradé d'en-tête | **exact** : `YekiColors.primary` (design_system) |
| 512-520 | (9 valeurs, doublons des lignes 17-40) | couleurs des puces de filtre par catégorie | doublons |

#### `widgets/yeki_fabs.dart` (18)
Cluster de FAB (bouton principal, bulle « Yéki IA », feuilles forum).

| Ligne | Hex | Usage | Token le plus proche |
|---|---|---|---|
| 23 | `0xFF8B5CF6` | constante locale violet | **exact** : `YekiColors.purple` |
| 24 | `0xFF10B981` | constante locale vert | **exact** : success |
| 28 | `0xFF3B82F6` | catégorie « leçon » | **exact** : `info` |
| 91 | `0xFF161B22` | fond feuille (sombre) | **exact** : `YColors.inkSurf` |
| 93 | `0xFF30363D` | bordure feuille | **exact** : `YColors.inkBorder` |
| 113 | `0xFF008088`, `0xFF39A0C2` | dégradé logo | 1er : aucun match ; 2ᵉ : **exact** `primaryLight`/`tealLight` |
| 139 | `0xFF008088` | icône « voir la discussion » | aucun exact |
| 261 | `0xFF008088` | FAB « Yéki IA » | aucun exact |
| 267 | `0xFF008088`, `0xFF39A0C2` | dégradé FAB IA | idem L113 |
| 276 | `0xFF3B82F6` | FAB « Forum » | **exact** : `info` |
| 494 | `0xFF008088`/`0xFF3B82F6` | getter `_accentColor` (IA vs Forum) | 2ᵉ exact `info` |
| 503 | `0xFF161B22` | fond feuille de chat | **exact** `inkSurf` |
| 505 | `0xFF30363D` | bordure feuille de chat | **exact** `inkBorder` |
| 587 | `0xFF1C2128` | fond champ de texte | **exact** `YColors.inkCard` |
| 589 | `0xFF30363D` | bordure champ de texte | **exact** `inkBorder` |

#### `widgets/modifier_cours_sheet.dart` (18)
Feuille « modifier un cours », sélecteur de couleur de cours.

| Ligne | Hex | Usage | Token le plus proche |
|---|---|---|---|
| 13 | `0xFF6A1B9A` | constante locale (usage flou) | aucun exact |
| 14 | `0xFF0D1B2A` | constante locale sombre | **exact** `bgDark`/`kADark` |
| 37-50 | 14 couleurs (`#6A1B9A, #008080, #1565C0, #2E7D32, #E65100, #C62828, #6A1B9A, #00838F, #283593, #558B2F, #AD1457, #4527A0, #00695C, #37474F`) | palette de 14 couleurs de cours | aucune ne correspond à un token existant |
| 96 | `0xFF008080` | couleur de cours par défaut | aucun exact |
| 390 | `0xFFF8F4FC` | fond de champ texte (teinte lavande) | aucun exact |

#### `widgets/form_preoccupation_sheet.dart` (14)
Constantes de couleur locales pour un formulaire — **12 des 14 dupliquent
exactement un token existant** (2 supplémentaires sont commentées/mortes
mais correspondraient aussi).

| Ligne | Hex | Const locale | Token exact dupliqué |
|---|---|---|---|
| 11 | `0xFF135F74` | `brandBackground` | `YekiColors.primaryDark` |
| 12 | `0xFFFF6B00` | `actionOrange` | `YekiColors.accent` |
| 13 | `0xFF1A1C1E` | `_textDark` | `YekiColors.textDark` |
| 14 | *(commentée)* `0xFF5A5C5E` | `_textMedium` | `YekiColors.textMedium` |
| 15 | `0xFF8A8C8E` | `_textLight` | `YekiColors.textLight` |
| 16 | `0xFFE0E4E8` | `_borderLight` | `YekiColors.borderLight` |
| 17 | *(commentée)* `0xFFD0D4D8` | `_borderMedium` | `YekiColors.borderMedium` |
| 18 | `0xFFF8FAFC` | `_bgLight` | `backgroundLight`/`bgLight` |
| 19 | `0xFFFFFFFF` | `_white` | `white` |
| 20 | `0xFF10B981` | `_green` | success |
| 21 | `0xFFEF4444` | `_red` | `YekiColors.error` |
| 22 | `0xFF3B82F6` | `_blue` | `info` |
| 23 | `0xFFA855F7` | `_purple` | catégorie `exercice` |
| 24 | `0xFFF97316` | `_orange` | `warning`/`YColors.orange` |

#### `widgets/creer_cours_sheet.dart` (13)
Palette de 12 couleurs de cours + repli de parsing hex.

| Ligne | Hex | Usage |
|---|---|---|
| 54-65 | `#008080, #6A1B9A, #1565C0, #00897B, #E65100, #C62828, #4527A0, #00695C, #283593, #6D4C41, #37474F, #558B2F` | palette de 12 couleurs de cours (aucun match token) |
| 872 | `0xFF008080` | repli si l'analyse hex échoue (doublon L54) |

#### `widgets/creer_departement_patch.dart` (12)
Formulaire « créer un département », sections concours/formation.

| Ligne | Hex | Usage | Token le plus proche |
|---|---|---|---|
| 146 | `0xFF8B5CF6` | titre section « concours » | **exact** `purple` |
| 222 | `0xFF008088` | titre section « formation » | aucun exact |
| 241, 246, 254, 264 | `0xFFF97316` (×4) | puce « Métier » sélectionnée (fond/bordure/icône/texte) | **exact** `warning`/`YColors.orange` |
| 282, 287, 295, 305 | `0xFF008088` (×4) | puce « Classique » sélectionnée | aucun exact |
| 340, 342 | `0xFF008088` (×2) | puce mode formation sélectionnée | aucun exact |

#### `views/pages/apprenants/lecons_cours.dart` (11)
Constantes locales — **les 11 dupliquent exactement un token existant**.

| Ligne | Hex | Const locale | Token exact dupliqué |
|---|---|---|---|
| 21 | `0xFF2884A0` | `brandPrimary` | `primary`/`kPrimary` |
| 22 | `0xFFFF6B00` | `brandGold` (mal nommée, c'est un orange) | `YekiColors.accent` |
| 23 | `0xFF1E293B` | `_textDark` | `textDark` (theme/yeki_design_system) |
| 24 | `0xFF5A5C5E` | `_textMedium` | `YekiColors.textMedium` (app_theme) |
| 25 | `0xFF94A3B8` | `_textLight` | `textFaint` (design_system) |
| 26 | `0xFFE2E8F0` | `_borderLight` | `borderLight` (design_system) |
| 27 | `0xFFF8FAFC` | `_bgLight` | `bgLight`/`backgroundLight` |
| 28 | `0xFFFFFFFF` | `_white` | `white` |
| 29 | `0xFF10B981` | `_green` | success |
| 30 | `0xFFEF4444` | `_red` | `YekiColors.error` |
| 31 | `0xFF3B82F6` | `_blue` | `info` |

#### `main.dart` (6)

| Ligne | Hex | Usage | Token le plus proche |
|---|---|---|---|
| 38 | `0xFF135F74` | `ThemeData.primaryColor` | **exact** `primaryDark` |
| 41 | `0xFFC5A059` | `accentColor` du `ColorScheme` | **exact** `gold` (app_theme) |
| 54 | `0xFFF4F4F4` | fond par défaut des champs texte | aucun exact (proche de `#F1F5F9`, pas identique) |
| 154 | `0xFF0D1B2A` | fond du splash screen | **exact** `bgDark`/`kADark` |
| 159 | `0xFF2884A0` | titre « Yéki » du splash | **exact** `primary` |
| 163 | `0xFF2884A0` | couleur du spinner du splash | **exact** `primary` |

### 2.2 Les 21 autres fichiers non listés par la consigne (80 occurrences)

| Fichier | Occurrences | Détail |
|---|---|---|
| `services/recharge_wallet_page.dart` | 12 | 11× `0xFF2884A0` (**exact** `primary`) + 1× `0xFF1A1C1E` (**exact** `textDark`) |
| `services/notification_service.dart` | 8 | 7× `0xFF135F74` (**exact** `primaryDark`) + 1× `0xFF8B5CF6` (**exact** `purple`) |
| `services/cached_pdf_viewer.dart` | 8 | 6× `0xFF135F74` (**exact** `primaryDark`), 1× `0xFF10B981` (success), 1× `0xFFF97316` (warning) |
| `services/update_service.dart` | 7 | 6× `0xFF135F74` (**exact** `primaryDark`) + 1× `0xFF10B981` (success) |
| `widgets/form_question_sheet.dart` | 6 | `0xFF008088` (aucun match), `0xFF0D1B2A` (**exact** `bgDark`), `0xFF1565C0`/`0xFF6A1B9A`/`0xFFE65100`/`0xFF2E7D32` (catégories, aucun match) |
| `views/pages/apprenants/classement_olympiade.dart` | 5 | `0xFFFFF8E1`, `0xFFE2A84B`×2 (**exact** `gold`), `0xFFF5F5F5`, `0xFFFFF3E0` (**exact** `YekiRoleColors.principalBg`) |
| `views/pages/apprenants/resultat_exercice_page.dart` | 4 | `0xFF1B5E20`/`0xFF2E7D32` (dégradé succès), `0xFFB71C1C`/`0xFFC62828` (dégradé échec) — aucun match |
| `views/pages/apprenants/passer_exercice.dart` | 4 | mêmes 4 valeurs que ci-dessus, dupliquées |
| `views/pages/apprenants/paiement_page.dart` | 4 | `0xFFFFCC00` (MTN, marque tierce), `0xFF FF6600` (Orange Money, marque tierce) ×2 chacune |
| `views/pages/apprenants/exercices_cours.dart` | 3 | `0xFFF1F5F9` (**exact** `backgroundAlt`), `0xFF059669` ×2 (aucun token nommé, correspond au 2ᵉ stop du dégradé succès de `yeki_design_extension.dart`) |
| `views/pages/apprenants/classement_departement_page.dart` | 3 | `0xFFFFD700` or médaille, `0xFFC0C0C0` argent, `0xFFCD7F32` bronze — aucun match (couleurs de médailles) |
| `views/pages/shared/profil_page.dart` | 2 | `0xFF1A3A4A`, `0xFF1565A0` (dégradé en-tête profil) — aucun match |
| `views/pages/enseignants/interface_enseignant_page.dart` | 2 | `0xFF0D2A3A` (proche de `bgDark` sans être identique), `0xFF1A3A4A` |
| `views/pages/apprenants/repetiteurs_page.dart` | 2 | `0xFF25D366` ×2 — vert WhatsApp, marque tierce légitime |
| `views/pages/apprenants/devoirs_cours_page.dart` | 2 | `0xFFF1F5F9` (**exact** `backgroundAlt`), `0xFF64748B` (**exact** `textMedium`) |
| `views/pages/apprenants/composer_devoir_page.dart` | 2 | `0xFFE0F4F4` ×2 (teinte teal claire, aucun match) |
| `services/cinetpay_webview_page.dart` | 2 | `0xFF2884A0` ×2 (**exact** `primary`) |
| `widgets/yeki_app_bar.dart` | 1 | `0xFF25D366` — vert WhatsApp, marque tierce |
| `widgets/wallet_page.dart` | 1 | `0xFF0D1B2A` (**exact** `bgDark`) |
| `views/pages/enseignants/detail_departement_page.dart` | 1 | `0xFF135F74` (**exact** `primaryDark`) |
| `views/pages/apprenants/detail_lecon_page.dart` | 1 | `0xFF60A5FA` (proche de `info` sans être identique) |

### 2.3 Constats utiles pour une future migration (non traités ici, simple observation)

- **Une couleur « teal fantôme » `#008088`** (différente de `#008080`, la
  teal CSS standard, et absente de tout token) revient dans 5 fichiers
  (`yeki_fabs.dart`, `creer_departement_patch.dart`,
  `modifier_cours_sheet.dart` en `#008080`, `creer_cours_sheet.dart`,
  `form_question_sheet.dart`) — clairement intentionnelle et répétée, pas
  accidentelle, mais n'a de foyer dans aucun système de design actuel.
- **Une palette de couleurs de cours/catégories** (`#6A1B9A`, `#1565C0`,
  `#C62828`, `#558B2F`, `#283593`, `#00695C`, `#E65100`, `#BF360C`, etc.)
  est partagée par 4 fichiers (`historique_page.dart`,
  `modifier_cours_sheet.dart`, `creer_cours_sheet.dart`,
  `form_question_sheet.dart`) sans équivalent dans aucun design system.
- **Couleurs de marque tierces légitimes**, à ne pas reprocher comme
  « style en dur manquant » : WhatsApp `#25D366`, MTN `#FFCC00`, Orange
  Money `#FF6600`, médailles or/argent/bronze.

---

## 3. Dette d'architecture

### 3.1 `setState(` — 610 occurrences (pas 575), 58 fichiers

`rg -o "setState\(" lib -g "*.dart" | wc -l` → **610**.

Top 10 fichiers :
1. `views/pages/apprenants/devoirs_cours_page.dart` — 37
2. `views/pages/apprenants/detail_lecon_page.dart` — 32
3. `views/auth/register_page.dart` — 31
4. `views/auth/forgot_password_flow.dart` — 31
5. `views/pages/apprenants/yeki_ia_chat_page.dart` — 29
6. `views/pages/apprenants/forum_page.dart` — 29
7. `views/pages/enseignants/admin_general_page.dart` — 25
8. `views/pages/apprenants/exercices_cours.dart` — 24
9. `views/pages/apprenants/passer_exercice.dart` — 23
10. `views/pages/apprenants/details_question_forum.dart` — 19

### 3.2 `http.*` direct — 53 fichiers (pas 48), aucune couche d'abstraction

53 fichiers appellent directement `http.get`/`post`/`put`/`patch`/`delete`.
57 fichiers importent `package:http/http.dart` si l'on compte aussi 4
fichiers qui utilisent `http.Request`/`http.MultipartRequest`/
`http.Response.fromStream` (`cache_manager.dart`, `download_manager.dart`,
`edit_profil_page.dart`, `yeki_fabs.dart`).

**Aucune classe `ApiClient`/`ApiService`/`HttpService` n'existe nulle
part.** Le seul semblant d'abstraction est `lib/core/constants/api_constants.dart`
(`ApiConstants` : quelques URLs en constantes ; `ApiHeaders` : 2 fonctions
statiques de construction d'en-têtes) — ni l'un ni l'autre ne wrap l'appel
HTTP lui-même, la gestion d'erreur, ou le parsing de réponse. `http`
direct est le **seul** pattern utilisé dans toute la base.

### 3.3 Navigation — 65 `Navigator.push` (pas 81)

| Variante | Compte |
|---|---|
| `Navigator.push(` | **65** |
| `Navigator.pushNamed(` | 3 |
| `Navigator.pushReplacement(` | 7 |
| `Navigator.pushReplacementNamed(` | 1 |
| `Navigator.pushAndRemoveUntil(` | 1 |
| **Total toutes variantes** | **77** |

Même en additionnant toutes les variantes, on obtient 77, pas 81 — écart
non expliqué, signalé tel quel plutôt que deviné.

### 3.4 `GoRouter` / `Riverpod` — 0 usage confirmé, mais dépendances mortes

- `GoRouter`/`go_router` : 0 import, 0 usage — mais **`pubspec.yaml`
  déclare `go_router: ^16.0.0`**. Dépendance morte.
- `Riverpod`/`flutter_riverpod`/`ConsumerWidget`/`ProviderScope` : 0 import,
  0 usage — mais **`pubspec.yaml` déclare `flutter_riverpod: ^2.4.0`**.
  Dépendance morte.
- Aucun `provider` (package séparé) ni `ChangeNotifier` non plus.
- **Gestion d'état réelle sur tout le projet : `StatefulWidget` +
  `setState()` uniquement**, aucune couche d'état partagée.

### 3.5 Accessibilité — 0 partout

`Semantics(` : 0. `semanticLabel:` : 0. `ExcludeSemantics` : 0.
`MergeSemantics` : 0. Aucun signal d'accessibilité nulle part dans `lib/`.

### 3.6 `PopScope` — confirmé, 1 seule occurrence, absence critique confirmée sur `passer_exercice.dart`

`PopScope` : exactement **1** occurrence, `composer_devoir_page.dart:388`.
Aucun `WillPopScope` (l'API dépréciée équivalente) nulle part dans le
projet.

```dart
// composer_devoir_page.dart, L388-398
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (!didPop && mounted) {
      if (_soumis) {
        if (mounted) Navigator.pop(context);
        return;
      }
      await _sortir();
    }
  },
  ...
```
Ce code intercepte **toute** tentative de sortie — bouton retour système,
geste, ET bouton croix in-app — et les fait toutes passer par `_sortir()`
(dialogue de confirmation, compteur de sorties, soumission automatique si
épuisé).

`passer_exercice.dart` (1213 lignes) : **confirmé, aucun `PopScope`,
`WillPopScope`, `onWillPop`, ni `canPop`.** L'écran d'épreuve en cours ne
protège qu'un bouton croix in-app (`_confirmExit()`, L1158) via son
`onPressed` — mais comme ce n'est **pas** un `PopScope`/`WillPopScope`, le
bouton retour matériel Android, le geste de bord iOS, et le bouton retour
du navigateur sur Flutter Web contournent tous cette confirmation et
ferment/quittent l'écran directement, **perdant l'épreuve en cours sans
confirmation ni soumission automatique**. Règle métier critique confirmée
non appliquée à l'endroit où elle compte le plus (une épreuve chronométrée,
à tentatives limitées, avec pénalités) — exactement ce que signale la
consigne.

---

## 4. `import 'dart:io'` — 13 fichiers, tous à base de `File`

Aucun de ces imports n'est protégé par une garde web (`kIsWeb` ou export
conditionnel) — chacun plante réellement sur cible Flutter Web
(`dart:io` n'y existe pas), confirmant la cause de l'erreur
« Unsupported operation: _Namespace » signalée sur la création d'exercice
avec image.

| Fichier:ligne | Fonctionnalité `dart:io` utilisée |
|---|---|
| `widgets/yeki_fabs.dart:7` | `File` |
| `services/cache_manager.dart:3` | `Directory`, `File` |
| `services/cached_video_player.dart:6` | `File` |
| `services/cached_pdf_viewer.dart:3` | `File` |
| `services/update_service.dart:4` | `Directory`, `File`, `Platform` |
| `services/facture_service.dart:6` | `File` |
| `services/download_manager.dart:6` | `Directory`, `File`, `Platform` |
| `views/pages/apprenants/detail_lecon_page.dart:8` | `File` |
| `views/pages/apprenants/details_question_forum.dart:8` | `File` |
| `views/pages/apprenants/yeki_ia_chat_page.dart:8` | `File` |
| `views/pages/apprenants/lecture_lecon_page.dart:7` | `File` |
| `views/pages/apprenants/exercices_cours.dart:7` | `File` |
| `views/pages/apprenants/forum_page.dart:9` | `File` |

---

## 5. Classes de widgets définies à l'intérieur des pages

`views/pages/apprenants/devoirs_cours_page.dart` (2817 lignes) contient
**14 déclarations de classe au total**, confirmant le chiffre de la
consigne — mais seulement 10 sont des widgets, les 4 autres sont des
classes de données :
- Widgets (10) : `DevoirsCoursPage`, `_DevoirsCoursPageState`,
  `_CreerDevoirSheet`, `_CreerDevoirSheetState`, `_DupliquerDevoirSheet`,
  `_DupliquerDevoirSheetState`, `_QuestionsSheet`, `_QuestionsSheetState`,
  `_GestionSoumissionsSheet`, `_GestionSoumissionsSheetState`
- Données (4, pas des widgets) : `DevoirCours`, `SoumissionItem`,
  `QuestionDevoirItem`, `ChoixItem`

**Ce n'est pas le pire fichier du projet une fois qu'on élargit la
recherche** (`^class .* extends (StatelessWidget|StatefulWidget|State<)`
sur `lib/views/pages/`) :

| # | Fichier | Classes-widgets |
|---|---|---|
| 1 | `views/pages/apprenants/formation_detail_page.dart` | **12** |
| 2 | `views/pages/apprenants/concours_detail_page.dart` | **11** |
| 3 | `views/pages/apprenants/devoirs_cours_page.dart` | 10 |
| 4 | `views/pages/apprenants/detail_lecon_page.dart` | 8 |
| 5 | `views/pages/enseignants/admin_general_page.dart` | 6 |

Motif systémique de « god files » (fichiers-pages qui accumulent tous
leurs sous-écrans/sheets/dialogues comme classes privées internes plutôt
que des fichiers séparés), pas isolé au fichier cité par la consigne.

---

## 6. `pubspec.yaml` — dépendances déclarées vs réellement utilisées

Chemin : `yeki_frontend/yeki/pubspec.yaml`.

| Package | Déclaré | Usage réel dans `lib/` |
|---|---|---|
| `flutter_riverpod` | `^2.4.0` | **0 usage** — dépendance morte |
| `go_router` | `^16.0.0` | **0 usage** — dépendance morte |
| `google_fonts` | `^6.1.0` | **1 fichier** (`core/design_system/yeki_design_system.dart`), 4 appels (`GoogleFonts.outfit`, `GoogleFonts.plusJakartaSans`, `GoogleFonts.plusJakartaSansTextTheme` ×2) — mais ses fonctions `yekiLightTheme()`/`yekiDarkTheme()` qui les utilisent ne sont **jamais appelées** nulle part (le fichier a même son propre commentaire : « à brancher dans MaterialApp(theme: yekiLightTheme, ...) », jamais fait) |
| `dio` | `^5.4.0` | **1 fichier** (`views/auth/register_page.dart`) — incohérence isolée face aux 53-57 fichiers en `http` direct |
| `http` | `^1.2.1` | 53 fichiers (appels directs) / 57 (import du package) |

**Confirmé absents de `pubspec.yaml`** (aucune occurrence trouvée) :
`flutter_quill`, `flutter_math_fork`, `firebase_messaging`,
`google_mobile_ads`.

**« Plus Jakarta Sans » — jamais réellement chargée, pour deux raisons
distinctes et cumulatives :**
1. `pubspec.yaml` ne déclare qu'**une seule** police dans sa section
   `fonts:` — `FredokaOne` (`assets/fonts/Fredoka-Regular.ttf`). Aucun
   fichier de police « Plus Jakarta Sans » n'existe sur le disque
   (`assets/fonts/` ne contient que `Fredoka-Regular.ttf`).
2. Le fichier de thème **le plus largement importé** (`core/theme/yeki_design_system.dart`,
   23 importeurs) hardcode `fontFamily: 'Plus Jakarta Sans'` en chaîne
   brute dans sa classe `YekiTextStyles` (4 occurrences) — sans asset
   correspondant, Flutter retombe silencieusement sur la police système
   par défaut.
3. Le **seul** endroit où `GoogleFonts.plusJakartaSans(...)` est
   correctement implémenté (`core/design_system/yeki_design_system.dart`,
   7 importeurs seulement) n'est jamais branché dans `MaterialApp` (voir
   ci-dessus) — donc même l'implémentation correcte est morte.

Conclusion : la charte typographique « Plus Jakarta Sans » n'a jamais été
rendue à l'écran depuis le début du projet, dans les deux chemins de code
qui la référencent, pour deux raisons différentes (police absente d'un
côté, thème jamais branché de l'autre).

---

## Notes méthodologiques

- Tous les comptages ont été produits par des commandes `rg`/`grep` réelles
  sur l'arborescence `lib/` telle qu'elle existe au 2026-07-18, pas
  estimés.
- Aucun fichier de code n'a été modifié pour produire cet audit — tâche
  purement documentaire, conformément à la consigne « NE RIEN MODIFIER ».
- Là où le chiffre vérifié diverge du chiffre donné par la consigne, les
  deux sont indiqués explicitement (voir tableau de synthèse en tête de
  document) — aucune correction silencieuse.
