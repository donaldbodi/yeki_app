// lib/features/olympiades/presentation/olympiades_page.dart
//
// Écran « olympiades » (apprenant) — liste des olympiades accessibles.
// Refondu en P8.3 (rituel P5.0) — remplace
// lib/views/pages/apprenants/olympiades_page.dart. Aucune maquette
// dédiée trouvée (tuiles de dashboard seulement) — le texte du ticket
// fait foi. Glassmorphism/dégradé décoratif de l'ancien fichier retiré
// (aucun composant Yk* équivalent — Container→YkCard, refonte technique
// standard, règle 4 : pas à demander).
//
// Correctif majeur (P8.3) : navigue désormais vers
// `AppRoute.olympiadeInscription` (route déjà enregistrée mais jamais
// appelée) au lieu d'ouvrir `InscriptionSheet` (supprimé, ne gérait
// AUCUN paiement — bug bloquant pour toute olympiade payante).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/olympiade_models.dart';

import 'olympiades_controller.dart';

class OlympiadesPage extends StatefulWidget {
  const OlympiadesPage({super.key});

  @override
  State<OlympiadesPage> createState() => _OlympiadesPageState();
}

class _OlympiadesPageState extends State<OlympiadesPage> {
  late final OlympiadesController _controller;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _controller = OlympiadesController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ouvrirInscription(OlympiadeApprenant o) {
    context.pushNamed(
      AppRoute.olympiadeInscription,
      pathParameters: {'olympiadeId': o.id.toString()},
      queryParameters: {
        'titre': o.titre,
        'reglement': o.description,
        'prixDesc': o.recompense,
        'datDebut': o.dateDebutOlympiade.toIso8601String(),
        'datFin': o.dateFinOlympiade.toIso8601String(),
        'prixParticipation': o.prixParticipation.toString(),
      },
    ).then((_) => _controller.charger());
  }

  void _ouvrirClassement(OlympiadeApprenant o) {
    context.pushNamed(
      AppRoute.olympiadeClassement,
      pathParameters: {'olympiadeId': o.id.toString()},
      queryParameters: {'titre': o.titre},
    );
  }

  void _lancerCompetition(OlympiadeApprenant o) {
    if (o.devoirId == null) return;
    context.pushNamed(
      AppRoute.devoirComposer,
      pathParameters: {'devoirId': o.devoirId.toString()},
      queryParameters: {
        'titre': o.titre,
        'dureeMin': o.dureeMinutes.toString(),
        'noteSur': o.noteSur.toInt().toString(),
      },
    );
  }

  void _handleTap(OlympiadeApprenant o) {
    if (o.statut == 'terminee' && o.afficherClassement) {
      _ouvrirClassement(o);
    } else if (o.statut == 'en_cours' && o.estInscrit) {
      _lancerCompetition(o);
    } else if (o.statut == 'inscription' && !o.estInscrit) {
      _ouvrirInscription(o);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: const Text('Olympiades')),
      body: AnimatedBuilder(animation: _controller, builder: (context, _) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.etat) {
      case OlympiadesEtat.chargement:
        return SingleChildScrollView(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkSkeleton.list(itemCount: 4, itemHeight: 180),
        );
      case OlympiadesEtat.erreur:
        return YkErrorState(
          message: _controller.erreurMessage ?? 'Une erreur est survenue.',
          onRetry: _controller.charger,
        );
      case OlympiadesEtat.pret:
        return _buildListe(context);
    }
  }

  Widget _buildListe(BuildContext context) {
    final affichees = _controller.affichees;
    return RefreshIndicator(
      onRefresh: _controller.charger,
      child: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        children: [
          YkSegmented<String>(
            segments: const [
              YkSegment(value: 'tous', label: 'Toutes'),
              YkSegment(value: 'inscription', label: 'Inscriptions'),
              YkSegment(value: 'en_cours', label: 'En cours'),
              YkSegment(value: 'terminee', label: 'Terminées'),
            ],
            selected: _controller.phaseFiltre,
            onChanged: _controller.filtrerPar,
          ),
          SizedBox(height: YkSpacing.md),
          if (affichees.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: YkEmptyState(
                title: 'Aucune olympiade',
                message: 'Ajustez vos filtres ou revenez plus tard.',
                icon: Icons.military_tech_outlined,
              ),
            )
          else
            for (final o in affichees) _buildCarte(context, o),
        ],
      ),
    );
  }

  Widget _buildCarte(BuildContext context, OlympiadeApprenant o) {
    final (label, couleur) = _statutInfo(o.statut);
    final inscriptionOuverteEtAVenir =
        o.statut == 'inscription' && o.dateDebutOlympiade.isAfter(DateTime.now());

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        variant: YkCardVariant.outlined,
        onTap: () => _handleTap(o),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.military_tech_rounded, color: couleur, size: 26),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Text(
                    o.titre,
                    style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                YkChip(label: label, variant: YkChipVariant.assist, accentColor: couleur),
              ],
            ),
            if (o.description.isNotEmpty) ...[
              SizedBox(height: YkSpacing.sm),
              Text(
                o.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            _ligneDate(context, Icons.how_to_reg_rounded, 'Fin des inscriptions', o.dateClotureInscription),
            _ligneDate(context, Icons.play_circle_rounded, "Début de l'épreuve", o.dateDebutOlympiade),
            if (inscriptionOuverteEtAVenir) ...[
              SizedBox(height: YkSpacing.sm),
              YkCountdown(
                key: ValueKey('countdown-olympiade-${o.id}'),
                duration: o.dateDebutOlympiade.difference(DateTime.now()),
                format: YkCountdownFormat.verbose,
                onExpired: _controller.charger,
              ),
            ],
            if (o.monInscription?.note != null) ...[
              SizedBox(height: YkSpacing.sm),
              YkCard(
                variant: YkCardVariant.filled,
                accentColor: YkColors.accent(context),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: YkColors.accent(context), size: 18),
                    SizedBox(width: YkSpacing.xs),
                    Text(
                      'Résultat : ${o.monInscription!.note!.toStringAsFixed(1)} / ${o.noteSur.toStringAsFixed(0)}',
                      style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (o.monInscription!.classement != null) ...[
                      const Spacer(),
                      Text(
                        'Rang : #${o.monInscription!.classement}',
                        style: YkTypography.bodyMd(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700, color: YkColors.accent(context)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: YkSpacing.md),
            _buildAction(context, o),
          ],
        ),
      ),
    );
  }

  Widget _ligneDate(BuildContext context, IconData icon, String label, DateTime valeur) {
    return Padding(
      padding: EdgeInsets.only(top: YkSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: YkColors.textTertiary(context)),
          SizedBox(width: YkSpacing.xs),
          Text('$label : ', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
          Expanded(
            child: Text(
              _dateFmt.format(valeur),
              style: YkTypography.bodySm(context).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, OlympiadeApprenant o) {
    if (o.statut == 'terminee' && o.afficherClassement) {
      return YkButton(
        label: 'Voir le classement',
        onPressed: () => _ouvrirClassement(o),
      );
    }
    if (o.statut == 'en_cours' && o.estInscrit) {
      return YkButton(label: 'Lancer la compétition', onPressed: () => _lancerCompetition(o));
    }
    if (o.statut == 'inscription' && !o.estInscrit) {
      return YkButton(label: "S'inscrire maintenant", onPressed: () => _ouvrirInscription(o));
    }
    if (o.statut == 'inscription' && o.estInscrit) {
      return YkCard(
        variant: YkCardVariant.filled,
        accentColor: YkColors.success,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: YkColors.success, size: 16),
            SizedBox(width: YkSpacing.xs),
            Text(
              'Enregistré — en attente du lancement',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.success, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  (String, Color) _statutInfo(String statut) => switch (statut) {
    'inscription' => ('Inscriptions', YkColors.success),
    'en_cours' => ('En cours', YkColors.info),
    'terminee' => ('Terminée', YkColors.warning),
    _ => ('Bientôt', YkColors.textTertiary(context)),
  };
}
