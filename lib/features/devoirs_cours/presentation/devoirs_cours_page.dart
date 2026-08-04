// lib/features/devoirs_cours/presentation/devoirs_cours_page.dart
//
// Onglet « Devoirs » d'un cours. Refondu en P7.4 (rituel P5.0) — même
// patron que `exercices_cours_page.dart` (P6.5) : UN widget de liste
// partagé apprenant/enseignant, gated par `RoleEnseignant?` (plus par
// le bool `isEnseignantPrincipal` de l'ancien fichier), aucune Scaffold
// ici (le parent porte l'AppBar/les tabs). La composition détaillée
// (énoncés/questions/soumissions) est réservée à l'enseignant via
// `AppRoute.devoirGererEnseignant` — jamais accessible côté apprenant.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/features/paiement/presentation/ouvrir_abonnement.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart' show RoleEnseignant;

import 'devoirs_cours_controller.dart';
import 'widgets/devoir_card.dart';
import 'widgets/devoir_form_sheet.dart';

class DevoirsCoursPage extends StatefulWidget {
  const DevoirsCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    this.onNaviguerForum,
    required this.courseColor,
    this.topPadding = 0,
  });

  final String coursId;
  final String coursTitre;
  final RoleEnseignant? role;
  final void Function(int questionId)? onNaviguerForum;
  final Color courseColor;

  /// Espace réservé en haut du contenu défilable — voir
  /// `LeconsCoursPage.topPadding` (même besoin, en-tête « verre dépoli »
  /// de `CoursDetailTabs`).
  final double topPadding;

  @override
  State<DevoirsCoursPage> createState() => _DevoirsCoursPageState();
}

class _DevoirsCoursPageState extends State<DevoirsCoursPage> {
  late final DevoirsCoursController _controller;

  bool get _canEdit =>
      widget.role == RoleEnseignant.enseignantPrincipal || widget.role == RoleEnseignant.enseignantCadre;

  @override
  void initState() {
    super.initState();
    _controller = DevoirsCoursController(coursId: int.parse(widget.coursId), canEdit: _canEdit);
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gerer(DevoirListItem devoir) {
    context
        .pushNamed(
          AppRoute.devoirGererEnseignant,
          pathParameters: {'devoirId': devoir.id.toString()},
          queryParameters: {'coursId': widget.coursId, 'coursTitre': widget.coursTitre},
        )
        .then((_) => _controller.charger());
  }

  void _demarrer(DevoirListItem devoir) {
    final soum = devoir.maSoumission;
    final route = (soum != null && soum.statut != 'en_cours') ? AppRoute.devoirResultat : AppRoute.devoirComposer;
    context
        .pushNamed(
          route,
          pathParameters: {'devoirId': devoir.id.toString()},
          queryParameters: {
            'titre': devoir.titre,
            if (route == AppRoute.devoirComposer) ...{
              'dureeMin': devoir.dureeMinutes.toString(),
              'noteSur': devoir.noteSur.toStringAsFixed(0),
              'typeCorrection': devoir.typeCorrection,
            } else ...{
              'coursId': widget.coursId,
              'coursTitre': widget.coursTitre,
            },
          },
        )
        .then((_) => _controller.charger());
  }

  Future<void> _dupliquer(DevoirListItem devoir) async {
    final ok = await _controller.dupliquer(devoir.id);
    if (!mounted) return;
    ok ? YkSnack.success(context, 'Devoir dupliqué (brouillon).') : YkSnack.error(context, 'Échec de la duplication.');
  }

  Future<void> _publier(DevoirListItem devoir) async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Publier ce devoir ?',
      message:
          'Après publication, vous ne pourrez plus ajouter ni modifier de question ni d\'énoncé sur ce devoir.',
      confirmLabel: 'Publier',
    );
    if (confirme != true) return;
    final message = await _controller.publier(devoir.id);
    if (!mounted) return;
    if (message != null) {
      YkSnack.success(context, message.isNotEmpty ? message : 'Devoir publié.');
    } else {
      YkSnack.error(context, 'Échec de la publication.');
    }
  }

  Future<void> _ouvrirFormulaire() async {
    await YkSheet.show(
      context: context,
      title: 'Nouveau devoir',
      bodyBuilder: (ctx) => DevoirFormSheet(
        onSubmit: ({
          required titre,
          required description,
          enonce,
          required dateDebut,
          required dateLimite,
          required dureeMinutes,
          required noteSur,
          required coefficient,
          required tentativesMax,
          required typeCorrection,
          fichierCorrection,
        }) => _controller.creer(
          titre: titre,
          description: description,
          enonce: enonce ?? '',
          dateDebut: dateDebut,
          dateLimite: dateLimite,
          dureeMinutes: dureeMinutes,
          noteSur: noteSur,
          coefficient: coefficient,
          tentativesMax: tentativesMax,
          typeCorrection: typeCorrection,
          fichierCorrection: fichierCorrection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.etat) {
      case DevoirsCoursEtat.chargement:
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md + widget.topPadding, YkSpacing.md, YkSpacing.md),
          child: YkSkeleton.list(itemCount: 4, itemHeight: 150),
        );
      case DevoirsCoursEtat.erreur:
        final message = _controller.erreurMessage ?? 'Une erreur est survenue.';
        return Padding(
          padding: EdgeInsets.only(top: widget.topPadding),
          child: message == kMessagePremiumRequis
              ? YkPremiumRequired(message: message, onSubscribe: () => ouvrirAbonnementPremium(context))
              : YkErrorState(message: message, onRetry: _controller.charger),
        );
      case DevoirsCoursEtat.pret:
        return _buildListe(context);
    }
  }

  Widget _buildListe(BuildContext context) {
    final devoirs = _controller.devoirs;
    return RefreshIndicator(
      onRefresh: _controller.charger,
      child: ListView(
        padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md + widget.topPadding, YkSpacing.md, YkSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Text('Devoirs', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
              const Spacer(),
              if (_canEdit)
                YkButton(label: 'Créer', icon: Icons.add, size: YkButtonSize.sm, onPressed: _ouvrirFormulaire),
            ],
          ),
          SizedBox(height: YkSpacing.md),
          if (devoirs.isEmpty)
            YkEmptyState(
              title: 'Aucun devoir',
              message: _canEdit
                  ? 'Créez un devoir avec le bouton « Créer » ci-dessus.'
                  : 'Aucun devoir disponible pour ce cours.',
            )
          else
            for (final devoir in devoirs)
              DevoirCard(
                devoir: devoir,
                courseColor: widget.courseColor,
                canEdit: _canEdit,
                onGerer: () => _gerer(devoir),
                onDemarrer: _canEdit ? null : () => _demarrer(devoir),
                onDupliquer: _canEdit ? () => _dupliquer(devoir) : null,
                onPublier: _canEdit ? () => _publier(devoir) : null,
              ),
        ],
      ),
    );
  }
}
