// lib/features/olympiades/presentation/olympiade_inscription_page.dart
//
// Écran « inscription à une olympiade » (apprenant). Refondu en P8.3
// (rituel P5.0) — remplace lib/views/pages/apprenants/olympiade_inscription_page.dart.
// Devient l'UNIQUE écran d'inscription : la route `AppRoute.olympiadeInscription`
// (déjà enregistrée) n'avait jusqu'ici AUCUN appelant — `olympiades_page.dart`
// ouvrait à la place `InscriptionSheet` (supprimé), qui ne gérait AUCUN
// paiement. Toute olympiade payante (le cas par défaut, 100 FCFA) était
// donc impossible à rejoindre depuis le seul chemin réellement emprunté.
//
// Glassmorphism/dégradé décoratif de l'ancien fichier retiré (refonte
// technique standard, règle 4 : pas à demander).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/wallet_repository.dart';

import 'olympiade_inscription_controller.dart';

class OlympiadeInscriptionPage extends StatefulWidget {
  const OlympiadeInscriptionPage({
    super.key,
    required this.olympiadeId,
    required this.titre,
    required this.reglement,
    required this.prixDesc,
    required this.datDebut,
    required this.datFin,
    this.prixParticipation = 0,
  });

  final int olympiadeId;
  final String titre;
  final String reglement;
  final String prixDesc;
  final DateTime datDebut;
  final DateTime datFin;
  final int prixParticipation;

  @override
  State<OlympiadeInscriptionPage> createState() => _OlympiadeInscriptionPageState();
}

class _OlympiadeInscriptionPageState extends State<OlympiadeInscriptionPage> {
  late final OlympiadeInscriptionController _controller;
  static final _dateFmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _controller = OlympiadeInscriptionController(olympiadeId: widget.olympiadeId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tenterInscription() async {
    if (!_controller.accepteReglement) {
      YkSnack.warning(context, 'Vous devez accepter le règlement.');
      return;
    }

    try {
      await _controller.inscrire();
      if (!mounted) return;
      YkSnack.success(context, 'Inscription confirmée ! Bonne chance.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCodes.paymentRequired) {
        final paye = await YkWalletDebitConfirmSheet.show(
          context,
          montant: widget.prixParticipation,
          description:
              'Cette olympiade demande un paiement de participation de '
              '${widget.prixParticipation} FCFA, prélevé sur votre portefeuille Yéki.',
          chargerSolde: () => WalletRepository().solde(),
          onPayer: () => _controller.payerParticipation(),
          onRecharger: () => context.pushNamed(AppRoute.recharge),
        );
        if (paye && mounted) await _tenterInscription();
      } else if (e.code == ApiErrorCodes.conflict) {
        YkSnack.warning(context, 'Vous êtes déjà inscrit à cette olympiade.');
        Navigator.of(context).pop(true);
      } else {
        YkSnack.error(context, e.message);
      }
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de connexion. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: YkGradientAppBar(titleWidget: Text(widget.titre, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => ListView(
          padding: EdgeInsets.all(YkSpacing.md),
          children: [
            _buildSection(
              context,
              'Calendrier',
              Icons.calendar_month_rounded,
              Column(
                children: [
                  _ligne(context, 'Début compétition', _dateFmt.format(widget.datDebut)),
                  SizedBox(height: YkSpacing.xs),
                  _ligne(context, 'Fin compétition', _dateFmt.format(widget.datFin)),
                ],
              ),
            ),
            if (widget.datDebut.isAfter(DateTime.now())) ...[
              SizedBox(height: YkSpacing.sm),
              Center(
                child: YkCountdown(
                  duration: widget.datDebut.difference(DateTime.now()),
                  format: YkCountdownFormat.verbose,
                  onExpired: () {},
                ),
              ),
            ],
            SizedBox(height: YkSpacing.md),
            if (widget.prixParticipation > 0) ...[
              _buildSection(
                context,
                'Participation',
                Icons.account_balance_wallet_rounded,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.prixParticipation} FCFA',
                      style: YkTypography.h3(context).copyWith(color: YkColors.accent(context)),
                    ),
                    SizedBox(height: YkSpacing.xxs),
                    Text(
                      "Prélevé sur votre portefeuille Yéki au moment de l'inscription.",
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: YkSpacing.md),
            ],
            if (widget.prixDesc.isNotEmpty) ...[
              _buildSection(context, 'Récompenses', Icons.stars_rounded, YkRichViewer(html: widget.prixDesc)),
              SizedBox(height: YkSpacing.md),
            ],
            if (widget.reglement.isNotEmpty) ...[
              _buildSection(
                context,
                'Règlement',
                Icons.gavel_rounded,
                Text(
                  widget.reglement,
                  style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context), height: 1.5),
                ),
              ),
              SizedBox(height: YkSpacing.md),
            ],
            _buildAntiTriche(context),
            SizedBox(height: YkSpacing.lg),
            _buildAcceptation(context),
            SizedBox(height: YkSpacing.lg),
            YkButton(
              label: widget.prixParticipation > 0
                  ? 'Payer ${widget.prixParticipation} FCFA et m\'inscrire'
                  : 'Confirmer mon inscription',
              isLoading: _controller.inscriptionEnCours,
              onPressed: (_controller.accepteReglement && !_controller.inscriptionEnCours)
                  ? _tenterInscription
                  : null,
            ),
            SizedBox(height: YkSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String titre, IconData icon, Widget contenu) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: YkColors.accent(context)),
              SizedBox(width: YkSpacing.xs),
              Text(titre, style: YkTypography.label(context).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          contenu,
        ],
      ),
    );
  }

  Widget _ligne(BuildContext context, String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
        Text(valeur, style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAntiTriche(BuildContext context) {
    const regles = [
      'Minuteur strict — soumission automatique à expiration',
      'Questions mélangées (ordre différent par participant)',
      "Toute sortie de l'application est détectée et pénalisée",
      'IP et heure de soumission enregistrées',
    ];
    return YkCard(
      variant: YkCardVariant.outlined,
      accentColor: YkColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_rounded, color: YkColors.warning, size: 18),
              SizedBox(width: YkSpacing.xs),
              Text(
                'Règles anti-triche',
                style: YkTypography.label(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.xs),
          for (final regle in regles)
            Padding(
              padding: EdgeInsets.only(top: YkSpacing.xxs),
              child: Text('•  $regle', style: YkTypography.bodySm(context).copyWith(color: YkColors.warning)),
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptation(BuildContext context) {
    return YkCard(
      variant: _controller.accepteReglement ? YkCardVariant.filled : YkCardVariant.outlined,
      accentColor: _controller.accepteReglement ? YkColors.accent(context) : null,
      onTap: _controller.toggleAccepte,
      semanticLabel: "J'ai lu et j'accepte le règlement de cette olympiade ainsi que les règles anti-triche",
      child: Row(
        children: [
          Icon(
            _controller.accepteReglement ? Icons.check_circle : Icons.circle_outlined,
            color: _controller.accepteReglement ? YkColors.accent(context) : YkColors.textTertiary(context),
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Text(
              "J'ai lu et j'accepte le règlement de cette olympiade ainsi que les règles anti-triche",
              style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
