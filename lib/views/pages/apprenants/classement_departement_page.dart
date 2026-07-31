// lib/views/pages/apprenants/classement_departement_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `ClassementRepository`
// (plus de `http`/`SharedPreferences` bruts) et les tokens/composants
// `Yk*` — `YkLeaderboard` remplace le `ListTile` par ligne fait main
// (podium graphique des 3 premiers, nouveauté visuelle absente de l'écran
// d'origine — voir le commentaire de tête d'`YkLeaderboard`).
//
// **Bug corrigé côté backend en même temps** : `classement[]` ne
// contenait ni `nom` ni `username` bien que cet écran les lisait déjà
// (`item['nom']`/`item['username']`) — les noms étaient donc
// systématiquement vides à l'affichage avant ce ticket. Corrigé dans
// `ClassementService.calculer_classement_departement`.
//
// **Accès aux périodes archivées** (exigence explicite du ticket) :
// aucun endpoint n'exposait `ClassementHistorique` avant ce ticket — créé
// (`GET .../periodes/`, `GET .../historique/`), consommé ici via un
// sélecteur de période au-dessus du classement.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/classement_repository.dart';

class ClassementDepartementPage extends StatefulWidget {
  final int departementId;
  final String departementNom;

  const ClassementDepartementPage({super.key, required this.departementId, required this.departementNom});

  @override
  State<ClassementDepartementPage> createState() => _ClassementDepartementPageState();
}

class _ClassementDepartementPageState extends State<ClassementDepartementPage> {
  final _repo = ClassementRepository();
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  bool _loading = true;
  String? _erreur;
  int? _monId;

  ClassementDepartement? _classementActuel;
  List<PeriodeArchivee> _periodes = [];
  PeriodeArchivee? _periodeSelectionnee;
  List<ClassementLigne>? _classementArchive;
  bool _chargementPeriode = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final resultats = await Future.wait([
        AuthRepository().getCurrentUser(),
        _repo.departement(widget.departementId),
        _repo.periodesArchivees(widget.departementId),
      ]);
      if (mounted) {
        setState(() {
          _monId = (resultats[0] as dynamic).id as int;
          _classementActuel = resultats[1] as ClassementDepartement;
          _periodes = resultats[2] as List<PeriodeArchivee>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Erreur de connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectionnerPeriode(PeriodeArchivee? periode) async {
    setState(() => _periodeSelectionnee = periode);
    if (periode == null) return;
    setState(() => _chargementPeriode = true);
    try {
      final classement = await _repo.classementArchive(widget.departementId, periode.periodeDebut);
      if (mounted) setState(() => _classementArchive = classement);
    } catch (_) {
      if (mounted) YkSnack.error(context, "Impossible de charger cette période archivée.");
    } finally {
      if (mounted) setState(() => _chargementPeriode = false);
    }
  }

  List<ClassementLigne> get _classementAffiche =>
      _periodeSelectionnee == null ? (_classementActuel?.classement ?? []) : (_classementArchive ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Text('Classement · ${widget.departementNom}'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _charger)],
      ),
      body: _loading
          ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 8))
          : _erreur != null
              ? YkEmptyState(icon: Icons.error_outline_rounded, title: 'Erreur', message: _erreur!, actionLabel: 'Réessayer', onAction: _charger)
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    padding: EdgeInsets.all(YkSpacing.md),
                    children: [
                      if (_classementActuel != null) _statsRow(context, _classementActuel!),
                      SizedBox(height: YkSpacing.md),
                      _selecteurPeriode(context),
                      SizedBox(height: YkSpacing.md),
                      if (_chargementPeriode)
                        Center(child: YkProgress(shape: YkProgressShape.circular))
                      else if (_classementAffiche.isEmpty)
                        YkEmptyState(icon: Icons.leaderboard_outlined, title: 'Aucun classement', message: 'Aucun apprenant classé pour le moment.')
                      else
                        YkLeaderboard(
                          entries: [
                            for (final ligne in _classementAffiche)
                              YkLeaderboardEntry(
                                rank: ligne.rang,
                                name: ligne.nom,
                                points: ligne.score.round(),
                                delta: ligne.progression?.round(),
                                isCurrentUser: ligne.apprenantId == _monId,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _statsRow(BuildContext context, ClassementDepartement classement) {
    return Row(
      children: [
        Expanded(child: YkStatCard(value: '${classement.totalParticipants}', label: 'Participants', icon: Icons.people_rounded)),
        SizedBox(width: YkSpacing.sm),
        Expanded(child: YkStatCard(value: classement.moyenne.toStringAsFixed(0), label: 'Moyenne', icon: Icons.star_rounded)),
        SizedBox(width: YkSpacing.sm),
        Expanded(child: YkStatCard(value: classement.meilleur.toStringAsFixed(0), label: 'Meilleur score', icon: Icons.emoji_events_rounded)),
      ],
    );
  }

  Widget _selecteurPeriode(BuildContext context) {
    return YkDropdown<PeriodeArchivee?>(
      label: 'Période',
      value: _periodeSelectionnee,
      items: [
        const YkDropdownItem(value: null, label: 'Période en cours'),
        for (final periode in _periodes)
          YkDropdownItem(
            value: periode,
            label: '${_dateFormat.format(periode.periodeDebut)} — ${_dateFormat.format(periode.periodeFin)}',
          ),
      ],
      onChanged: _selectionnerPeriode,
    );
  }
}
