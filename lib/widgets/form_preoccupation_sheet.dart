// lib/widgets/form_preoccupation_sheet.dart
//
// Refondu en P10.5 (rituel P5.0). Corrige le bug transverse « rien ne
// s'affiche dans le forum après soumission » : `cours_id` n'était ajouté
// au corps POST QUE pour la branche `lecon` — les branches `exercice`/
// `devoir` l'omettaient, alors qu'une question sans `cours_id` n'apparaît
// jamais dans le forum filtré par cours. Corrigé À LA SOURCE dans
// `ForumRepository.creerQuestion` (ajoute `cours_id` dès que `coursId` est
// fourni, indépendamment de `source`), donc corrigé pour ce fichier ET
// pour tout futur appelant du repository.
//
// Navigation post-envoi simplifiée : le backend renvoie la question créée
// COMPLÈTE (`id`, `cours_id`, `cours_titre`) — on navigue directement vers
// `AppRoute.forumQuestionDetail` avec CET `id`, plutôt que vers l'onglet
// Forum d'un cours en espérant qu'elle y apparaisse (l'ancien code avait
// trois branches de navigation différentes selon le contexte d'appel ;
// `tabController`/`onNaviguerForum` n'étaient en réalité jamais fournis
// par aucun des 3 appelants réels de `ouvrirPreoccupation` — code mort
// supprimé).
//
// Bascule complète vers `ForumRepository` (plus de `http`/
// `SharedPreferences` bruts) et `YkSheet`/`Yk*` (plus de 14 couleurs en
// dur — rule 2).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/forum_repository.dart';
import 'package:yeki/widgets/forum_style.dart';

void ouvrirPreoccupation({
  required BuildContext context,
  required String source,
  String contenuPrefill = '',
  int? leconId,
  String? leconTitre,
  int? coursId,
  String? coursTitre,
  int? coursColor,
  int? exerciceId,
  String? exerciceTitre,
  int? devoirId,
  String? devoirTitre,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PreoccupationSheet(
      source: source,
      contenuPrefill: contenuPrefill,
      leconId: leconId,
      leconTitre: leconTitre,
      coursId: coursId,
      coursTitre: coursTitre,
      coursColor: coursColor,
      exerciceId: exerciceId,
      exerciceTitre: exerciceTitre,
      devoirId: devoirId,
      devoirTitre: devoirTitre,
    ),
  );
}

class _PreoccupationSheet extends StatefulWidget {
  const _PreoccupationSheet({
    required this.source,
    required this.contenuPrefill,
    this.leconId,
    this.leconTitre,
    this.coursId,
    this.coursTitre,
    this.coursColor,
    this.exerciceId,
    this.exerciceTitre,
    this.devoirId,
    this.devoirTitre,
  });

  final String source;
  final String contenuPrefill;
  final int? leconId;
  final String? leconTitre;
  final int? coursId;
  final String? coursTitre;
  final int? coursColor;
  final int? exerciceId;
  final String? exerciceTitre;
  final int? devoirId;
  final String? devoirTitre;

  @override
  State<_PreoccupationSheet> createState() => _PreoccupationSheetState();
}

class _PreoccupationSheetState extends State<_PreoccupationSheet> {
  final _ctrl = TextEditingController();
  final _repo = ForumRepository();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.contenuPrefill;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _ctrl.text.trim();
    if (texte.isEmpty) {
      YkSnack.error(context, 'Écrivez votre question.');
      return;
    }

    setState(() => _sending = true);
    try {
      final question = await _repo.creerQuestion(
        contenu: texte,
        source: widget.source,
        leconId: widget.leconId,
        leconTitre: widget.leconTitre,
        coursId: widget.coursId,
        coursTitre: widget.coursTitre,
        exerciceId: widget.exerciceId,
        exerciceTitre: widget.exerciceTitre,
        devoirId: widget.devoirId,
        devoirTitre: widget.devoirTitre,
      );
      if (!mounted) return;
      Navigator.pop(context);

      final newId = question['id'] as int?;
      if (newId != null) {
        context.pushNamed(
          AppRoute.forumQuestionDetail,
          pathParameters: {'questionId': newId.toString()},
          queryParameters: {
            if (widget.coursColor != null) 'coursColor': widget.coursColor.toString(),
          },
        );
      }
      YkSnack.success(context, 'Question envoyée au forum !');
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _contexteLabel() {
    switch (widget.source) {
      case 'lecon':
        return widget.leconTitre ?? '';
      case 'exercice':
        return widget.exerciceTitre ?? '';
      case 'devoir':
        return widget.devoirTitre ?? '';
      default:
        return 'Question libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = sourcePreoccupationCouleur(context, widget.source);
    final icone = sourcePreoccupationIcone(widget.source);
    final contexteLabel = _contexteLabel();

    return Container(
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(YkRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: YkSpacing.lg,
        right: YkSpacing.lg,
        top: YkSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + YkSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: YkColors.border(context),
                borderRadius: BorderRadius.circular(YkRadius.full),
              ),
            ),
          ),
          SizedBox(height: YkSpacing.lg),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: couleur.withValues(alpha: 0.12),
                child: Icon(icone, color: couleur, size: 20),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poser une question',
                      style: YkTypography.h4(
                        context,
                      ).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    if (contexteLabel.isNotEmpty)
                      Text(
                        contexteLabel,
                        style: YkTypography.bodySm(context).copyWith(color: couleur),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.md),
          YkCard(
            variant: YkCardVariant.filled,
            accentColor: couleur,
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: couleur),
                SizedBox(width: YkSpacing.xs),
                Expanded(
                  child: Text(
                    'Depuis ${sourcePreoccupationLabel(widget.source)} : $contexteLabel',
                    style: YkTypography.bodySm(context).copyWith(color: couleur),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.md),
          YkTextField(
            controller: _ctrl,
            type: YkTextFieldType.multiline,
            maxLines: 5,
            autofocus: true,
            hint: 'Décrivez votre préoccupation en détail...',
          ),
          SizedBox(height: YkSpacing.md),
          YkButton(
            label: 'Envoyer au forum',
            icon: Icons.send_rounded,
            isLoading: _sending,
            onPressed: _sending ? null : _envoyer,
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Vous serez redirigé vers le forum après envoi.',
            style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
          ),
        ],
      ),
    );
  }
}
