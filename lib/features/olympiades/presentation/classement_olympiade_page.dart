// lib/features/olympiades/presentation/classement_olympiade_page.dart
//
// Écran « classement d'olympiade » (apprenant). Refondu en P8.3 (rituel
// P5.0) — remplace lib/views/pages/apprenants/classement_olympiade.dart.
//
// Corrige un bug réel : l'ancien fichier faisait `jsonDecode(res.body)
// as List`, un cast direct qui échoue dès que la réponse n'est pas un
// tableau brut — or `ClassementOlympiadeView` (backend) hérite de
// `PaginatedListMixin` et renvoie `{results, count, next, previous}`.
// Corrige aussi le bug `Olympiade.statut_auto` (accents, P8.3) qui
// rendait cet écran indéfiniment inaccessible (403) quel que soit
// l'état réel de l'olympiade.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import 'classement_olympiade_controller.dart';

class ClassementOlympiadePage extends StatefulWidget {
  const ClassementOlympiadePage({super.key, required this.olympiadeId, required this.titre});

  final int olympiadeId;
  final String titre;

  @override
  State<ClassementOlympiadePage> createState() => _ClassementOlympiadePageState();
}

class _ClassementOlympiadePageState extends State<ClassementOlympiadePage> {
  late final ClassementOlympiadeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClassementOlympiadeController(olympiadeId: widget.olympiadeId);
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: YkGradientAppBar(titleWidget: Text('Classement — ${widget.titre}', overflow: TextOverflow.ellipsis)),
      body: AnimatedBuilder(animation: _controller, builder: (context, _) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.etat) {
      case ClassementOlympiadeEtat.chargement:
        return SingleChildScrollView(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkSkeleton.list(itemCount: 6, itemHeight: 56),
        );
      case ClassementOlympiadeEtat.erreur:
        return YkErrorState(
          message: _controller.erreurMessage ?? 'Une erreur est survenue.',
          onRetry: _controller.charger,
        );
      case ClassementOlympiadeEtat.pret:
        if (_controller.entrees.isEmpty) {
          return const YkEmptyState(
            title: 'Aucun participant classé',
            message: 'Le classement sera disponible une fois les copies corrigées.',
            icon: Icons.leaderboard_outlined,
          );
        }
        return Padding(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkLeaderboard(
            entries: [
              for (final e in _controller.entrees)
                YkLeaderboardEntry(
                  rank: e.rang,
                  // `nom_complet` (nouveau, jamais lu par l'ancien fichier —
                  // qui n'affichait que `username`) — repli si vide.
                  name: e.nomComplet.isNotEmpty ? e.nomComplet : e.username,
                  // `YkLeaderboardEntry.points` est un entier (composant
                  // partagé avec le classement département, non décimal) —
                  // la note réelle sur 20 peut avoir des décimales
                  // (multiples de 0.25) : arrondie pour ce rendu podium,
                  // sans prétendre à une précision qu'il n'affiche pas.
                  points: e.noteSur20.round(),
                ),
            ],
          ),
        );
    }
  }
}
