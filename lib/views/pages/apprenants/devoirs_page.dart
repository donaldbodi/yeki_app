// lib/views/pages/apprenants/devoirs_page.dart
//
// Refondu en P11.2 (rituel P5.0, migration mécanique comme le forum en
// P10.5 — même volume, même risque sans QA visuelle) : bascule vers
// `DevoirRepository.listMine()` (plus de `http`/`SharedPreferences` bruts)
// et les tokens/composants `Yk*` (plus de `YekiColors`/`YekiButton`/
// glassmorphism codée en dur). `DevoirItem` déménagé vers
// `devoir_models.dart` (P11.2 : ancien `DevoirModel`/`OlympiadeInfo` du
// même fichier étaient du code mort, retirés).
//
// Cache hors-ligne (`OfflineService`) conservé à l'identique — le seul
// changement est la source des données fraîches (repository au lieu de
// `http` direct), pas la logique de repli hors-ligne elle-même.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/devoir_repository.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/services/offline_service.dart';
import 'package:yeki/services/sync_service.dart';
import 'package:yeki/views/pages/apprenants/devoir_models.dart' show DevoirItem;

class _TypeDevoirTab {
  const _TypeDevoirTab(this.code, this.icon);
  final String code;
  final IconData icon;
}

Color _couleurType(BuildContext context, String typeDevoir) {
  switch (typeDevoir) {
    case 'cursus':
      return YkColors.info;
    case 'concours':
      return YkColors.accent(context);
    case 'formation_classique':
      return YkColors.success;
    case 'formation_metier':
      return YkColors.warning;
    case 'olympiade':
      return YkColors.accent(context);
    default:
      return YkColors.textSecondary(context);
  }
}

Color _couleurStatut(BuildContext context, String? statutApprenant) {
  switch (statutApprenant) {
    case 'non_commence':
      return YkColors.accent(context);
    case 'en_cours':
      return YkColors.info;
    case 'soumis':
      return YkColors.warning;
    case 'corrige':
      return YkColors.success;
    case 'en_retard':
      return YkColors.error;
    default:
      return YkColors.accent(context);
  }
}

IconData _iconePourType(String typeDevoir) {
  switch (typeDevoir) {
    case 'cursus':
      return Icons.school_rounded;
    case 'concours':
      return Icons.emoji_events_rounded;
    case 'formation_classique':
      return Icons.account_balance_rounded;
    case 'formation_metier':
      return Icons.work_rounded;
    case 'olympiade':
      return Icons.military_tech_rounded;
    default:
      return Icons.assignment_rounded;
  }
}

String _libelleType(String code) {
  switch (code) {
    case 'Tous':
      return 'Tous';
    case 'cursus':
      return 'Cursus';
    case 'concours':
      return 'Concours';
    case 'formation_classique':
      return 'Formation';
    case 'formation_metier':
      return 'Métier';
    case 'olympiade':
      return 'Olympiade';
    default:
      return code;
  }
}

String _libelleStatut(String s) {
  switch (s) {
    case 'non_commence':
      return 'À faire';
    case 'en_cours':
      return 'En cours';
    case 'soumis':
      return 'Soumis';
    case 'corrige':
      return 'Corrigé';
    case 'en_retard':
      return 'En retard';
    default:
      return s;
  }
}

class DevoirsPage extends StatefulWidget {
  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  final bool estEnseignantPrincipal;

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage> {
  final _repo = DevoirRepository();

  bool _loading = true;
  bool _enErreur = false;

  List<DevoirItem> _tous = const [];
  List<DevoirItem> _affiches = const [];

  String _typeSelectionne = 'Tous';
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String _statutSelectionne = 'Tous';
  String _recherche = '';

  List<String> _niveaux = const [];

  static const _types = [
    _TypeDevoirTab('Tous', Icons.grid_view_rounded),
    _TypeDevoirTab('cursus', Icons.school_rounded),
    _TypeDevoirTab('concours', Icons.emoji_events_rounded),
    _TypeDevoirTab('formation_classique', Icons.account_balance_rounded),
    _TypeDevoirTab('formation_metier', Icons.work_rounded),
    _TypeDevoirTab('olympiade', Icons.military_tech_rounded),
  ];

  static const _matieres = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'SVT',
    'Informatique',
    'Français',
    'Anglais',
    'Histoire-Géo',
    'Philosophie',
    'Économie',
    'Autre',
  ];

  static const _statuts = ['non_commence', 'en_cours', 'soumis', 'corrige', 'en_retard'];

  @override
  void initState() {
    super.initState();
    _initOffline();
    _charger();
    _chargerNiveaux();
  }

  Future<void> _initOffline() async {
    await OfflineService.init();
    SyncService().startAutoSync();
  }

  @override
  void dispose() {
    SyncService().stopAutoSync();
    super.dispose();
  }

  Future<void> _chargerNiveaux() async {
    try {
      final niveaux = await FormationRepository().niveaux();
      if (mounted) setState(() => _niveaux = niveaux);
    } catch (_) {
      // Filtre niveau simplement vide en cas d'échec réseau — non
      // bloquant, cohérent avec le reste de cet écran.
    }
  }

  Future<void> _charger({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _enErreur = false;
      });
    }
    try {
      final devoirs = await _repo.listMine();
      if (!mounted) return;
      await OfflineService.cacheDevoirs('all_devoirs', devoirs.map((d) => d.toJson()).toList());
      OfflineService.isOnline = true;
      setState(() {
        _tous = devoirs;
        _loading = false;
        _appliquerFiltres();
      });
    } on ApiException catch (_) {
      OfflineService.isOnline = false;
      _chargerDepuisCache();
    } catch (_) {
      OfflineService.isOnline = false;
      _chargerDepuisCache();
    }
  }

  void _chargerDepuisCache() {
    final cached = OfflineService.getCachedDevoirs('all_devoirs');
    if (mounted) {
      setState(() {
        if (cached != null) {
          _tous = cached.map((d) => DevoirItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltres();
        } else {
          _enErreur = true;
        }
        _loading = false;
      });
    }
  }

  void _appliquerFiltres() {
    var temp = _tous;
    if (_typeSelectionne != 'Tous') {
      temp = temp.where((d) => d.typeDevoir == _typeSelectionne).toList();
    }
    if (_matiereSelectionnee != null) {
      temp = temp.where((d) => d.matiere == _matiereSelectionnee).toList();
    }
    if (_niveauSelectionne != null) {
      temp = temp.where((d) => d.niveau == _niveauSelectionne).toList();
    }
    if (_statutSelectionne != 'Tous') {
      temp = temp.where((d) => d.statutApprenant == _statutSelectionne).toList();
    }
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      temp = temp.where((d) => d.titre.toLowerCase().contains(q)).toList();
    }
    setState(() => _affiches = temp);
  }

  int get _aFaire => _tous.where((d) => d.statutApprenant == 'non_commence').length;
  int get _enRetard => _tous.where((d) => d.statutApprenant == 'en_retard').length;

  void _ouvrirDevoir(DevoirItem d) {
    context
        .pushNamed(
          AppRoute.devoirComposer,
          pathParameters: {'devoirId': d.id.toString()},
          queryParameters: {
            'titre': d.titre,
            'dureeMin': d.dureeMinutes.toString(),
            'noteSur': d.noteSur.toInt().toString(),
          },
        )
        .then((_) => _charger());
  }

  void _voirResultat(DevoirItem d) {
    context.pushNamed(
      AppRoute.devoirResultat,
      pathParameters: {'devoirId': d.id.toString()},
      queryParameters: {'titre': d.titre},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: _loading
            ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 180))
            : _enErreur
            ? YkEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Impossible de charger vos devoirs',
                message: 'Vérifiez votre connexion puis réessayez.',
                actionLabel: 'Réessayer',
                onAction: _charger,
              )
            : RefreshIndicator(
                onRefresh: () => _charger(silent: true),
                child: ListView(
                  padding: EdgeInsets.all(YkSpacing.md),
                  children: [
                    _buildTitre(context),
                    SizedBox(height: YkSpacing.md),
                    _buildStats(context),
                    SizedBox(height: YkSpacing.md),
                    YkTextField(
                      type: YkTextFieldType.search,
                      hint: 'Rechercher un devoir…',
                      onChanged: (v) {
                        _recherche = v;
                        _appliquerFiltres();
                      },
                    ),
                    SizedBox(height: YkSpacing.md),
                    _buildTypeChips(context),
                    SizedBox(height: YkSpacing.sm),
                    _buildFiltres(context),
                    SizedBox(height: YkSpacing.md),
                    Row(
                      children: [
                        Text(
                          'Vos devoirs',
                          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                        const Spacer(),
                        YkBadge(variant: YkBadgeVariant.label, label: '${_affiches.length}', color: YkColors.accent(context)),
                      ],
                    ),
                    SizedBox(height: YkSpacing.sm),
                    if (_affiches.isEmpty)
                      YkEmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Aucun devoir trouvé',
                        message: 'Ajustez vos filtres pour voir plus de résultats.',
                      )
                    else
                      for (final devoir in _affiches) _buildCarteDevoir(context, devoir),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTitre(BuildContext context) {
    return Row(
      children: [
        Text('Mes devoirs', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
        SizedBox(width: YkSpacing.xs),
        YkBadge(variant: YkBadgeVariant.label, label: 'ÉVALUATIONS', color: YkColors.accent(context)),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Total', '${_tous.length}', Icons.assignment_rounded, YkColors.accent(context))),
        SizedBox(width: YkSpacing.sm),
        Expanded(child: _buildStatCard(context, 'À faire', '$_aFaire', Icons.pending_rounded, YkColors.info)),
        SizedBox(width: YkSpacing.sm),
        Expanded(child: _buildStatCard(context, 'En retard', '$_enRetard', Icons.warning_rounded, YkColors.error)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String valeur, IconData icon, Color couleur) {
    return YkCard(
      variant: YkCardVariant.filled,
      child: Column(
        children: [
          Icon(icon, size: 20, color: couleur),
          SizedBox(height: YkSpacing.xxs),
          Text(valeur, style: YkTypography.h4(context).copyWith(color: couleur)),
          Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _buildTypeChips(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, _) => SizedBox(width: YkSpacing.xs),
        itemBuilder: (context, index) {
          final type = _types[index];
          final couleur = type.code == 'Tous' ? YkColors.accent(context) : _couleurType(context, type.code);
          return YkChip(
            label: _libelleType(type.code),
            variant: YkChipVariant.filter,
            selected: _typeSelectionne == type.code,
            accentColor: couleur,
            avatar: Icon(type.icon, size: 14, color: couleur),
            onSelected: (_) {
              setState(() => _typeSelectionne = type.code);
              _appliquerFiltres();
            },
          );
        },
      ),
    );
  }

  Widget _buildFiltres(BuildContext context) {
    final aUnFiltre = _matiereSelectionnee != null || _niveauSelectionne != null || _statutSelectionne != 'Tous';
    return Row(
      children: [
        Expanded(
          child: YkDropdown<String>(
            label: 'Matière',
            value: _matiereSelectionnee,
            items: [for (final m in _matieres) YkDropdownItem(value: m, label: m)],
            onChanged: (v) {
              setState(() => _matiereSelectionnee = v);
              _appliquerFiltres();
            },
          ),
        ),
        SizedBox(width: YkSpacing.xs),
        Expanded(
          child: YkDropdown<String>(
            label: 'Niveau',
            value: _niveauSelectionne,
            items: [for (final n in _niveaux) YkDropdownItem(value: n, label: n)],
            onChanged: (v) {
              setState(() => _niveauSelectionne = v);
              _appliquerFiltres();
            },
          ),
        ),
        SizedBox(width: YkSpacing.xs),
        Expanded(
          child: YkDropdown<String>(
            label: 'Statut',
            value: _statutSelectionne == 'Tous' ? null : _statutSelectionne,
            items: [for (final s in _statuts) YkDropdownItem(value: s, label: _libelleStatut(s))],
            onChanged: (v) {
              setState(() => _statutSelectionne = v ?? 'Tous');
              _appliquerFiltres();
            },
          ),
        ),
        if (aUnFiltre)
          YkIconButton(
            icon: Icons.clear_rounded,
            label: 'Effacer les filtres',
            variant: YkIconButtonVariant.ghost,
            onPressed: () {
              setState(() {
                _matiereSelectionnee = null;
                _niveauSelectionne = null;
                _statutSelectionne = 'Tous';
              });
              _appliquerFiltres();
            },
          ),
      ],
    );
  }

  Widget _buildCarteDevoir(BuildContext context, DevoirItem d) {
    final joursRestants = d.dateLimite.difference(DateTime.now()).inDays;
    final estExpire = joursRestants < 0;
    final couleurType = _couleurType(context, d.typeDevoir);

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        onTap: () {
          if (d.estCorrige && d.noteApprenant != null) {
            _voirResultat(d);
          } else if (!estExpire || d.aSoumis) {
            _ouvrirDevoir(d);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: couleurType.withValues(alpha: 0.12),
                  child: Icon(_iconePourType(d.typeDevoir), color: couleurType, size: 20),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.titre,
                        style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: YkSpacing.xxs),
                      Row(
                        children: [
                          YkBadge(variant: YkBadgeVariant.label, label: d.typeLabel, color: couleurType),
                          SizedBox(width: YkSpacing.xxs),
                          YkBadge(
                            variant: YkBadgeVariant.label,
                            label: d.statutLabel,
                            color: _couleurStatut(context, d.statutApprenant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (d.description.isNotEmpty) ...[
              SizedBox(height: YkSpacing.xs),
              Text(
                d.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
              decoration: BoxDecoration(
                color: YkColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(YkRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoIcone(context, Icons.layers_outlined, '${d.matiere} • ${d.niveau}'),
                  _infoIcone(context, Icons.quiz_rounded, '${d.nbQuestions} questions'),
                  _infoIcone(context, Icons.timer_rounded, '${d.dureeMinutes} min'),
                ],
              ),
            ),
            if (d.estCorrige && d.noteApprenant != null) ...[
              SizedBox(height: YkSpacing.sm),
              YkCard(
                variant: YkCardVariant.filled,
                accentColor: YkColors.success,
                child: Row(
                  children: [
                    Icon(Icons.grade_rounded, color: YkColors.success, size: 18),
                    SizedBox(width: YkSpacing.xs),
                    Text(
                      'Note : ${d.noteApprenant!.toStringAsFixed(1)} / ${d.noteSur.toStringAsFixed(0)}',
                      style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    const Spacer(),
                    YkBadge(
                      variant: YkBadgeVariant.label,
                      label: '${((d.noteApprenant! / d.noteSur) * 100).toStringAsFixed(0)}%',
                      color: YkColors.success,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Expanded(child: _buildDelai(context, joursRestants, estExpire)),
                SizedBox(width: YkSpacing.sm),
                _buildBoutonAction(context, d, estExpire),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIcone(BuildContext context, IconData icon, String texte) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: YkColors.textSecondary(context)),
          SizedBox(width: YkSpacing.xxs),
          Flexible(
            child: Text(
              texte,
              style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelai(BuildContext context, int joursRestants, bool estExpire) {
    if (estExpire) {
      return YkBadge(variant: YkBadgeVariant.label, label: 'Clôturé', color: YkColors.error);
    }
    final couleur = joursRestants < 3
        ? YkColors.error
        : (joursRestants < 7 ? YkColors.warning : YkColors.success);
    return YkBadge(
      variant: YkBadgeVariant.label,
      label: '$joursRestants jour${joursRestants > 1 ? 's' : ''}',
      color: couleur,
    );
  }

  Widget _buildBoutonAction(BuildContext context, DevoirItem d, bool estExpire) {
    if (d.estCorrige && d.noteApprenant != null) {
      return YkButton(label: 'Voir résultat', variant: YkButtonVariant.secondary, onPressed: () => _voirResultat(d));
    }
    if (estExpire && !d.aSoumis) return const SizedBox.shrink();
    return YkButton(
      label: d.estEnCours ? 'Continuer' : 'Commencer',
      onPressed: () => _ouvrirDevoir(d),
    );
  }
}
