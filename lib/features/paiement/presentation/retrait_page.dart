// lib/features/paiement/presentation/retrait_page.dart
//
// Écran de demande de retrait (cadres, `AppRoute.retrait`, P9.3) — nouveau,
// aucun écran équivalent n'existait côté frontend. Un retrait est un envoi
// de Yéki VERS le cadre (pas un dépôt) : `YkManualPaymentFlow(sens:
// retrait)` saute l'étape « Instructions » USSD, qui n'a pas de sens ici
// (aucun code à composer côté cadre). Voir docs/ecarts/wallet.md.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import 'retrait_controller.dart';

class RetraitPage extends StatefulWidget {
  const RetraitPage({super.key});

  @override
  State<RetraitPage> createState() => _RetraitPageState();
}

class _RetraitPageState extends State<RetraitPage> {
  late final RetraitController _controller;
  final TextEditingController _montantCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RetraitController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _lancerFlux() async {
    final montant = int.tryParse(_montantCtrl.text.trim());
    final params = _controller.parametres;
    if (montant == null || montant <= 0 || params == null) return;

    final ok = await YkManualPaymentFlow.show(
      context,
      sens: YkPaiementSens.retrait,
      montant: montant,
      titre: 'Retrait vers Mobile Money',
      ussdOrange: params.ussdOrangeMoney,
      ussdMtn: params.ussdMtnMomo,
      numeroDepotOrange: params.numeroDepotOrange,
      numeroDepotMtn: params.numeroDepotMtn,
      nomAfficheDepot: params.nomAfficheDepot,
      whatsappServiceClient: params.whatsappServiceClient,
      delaiValidationMinutes: params.delaiValidationPaiementMinutes,
      onSoumettre: _controller.demanderRetrait,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: const Text('Demande de retrait')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.chargement) {
            return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 3));
          }
          if (_controller.enErreur) {
            return YkErrorState(
              message: 'Impossible de charger votre solde.',
              cause: 'Vérifiez votre connexion internet.',
              onRetry: _controller.charger,
            );
          }
          return ListView(
            padding: EdgeInsets.all(YkSpacing.md),
            children: [
              YkCard(
                variant: YkCardVariant.filled,
                accentColor: YkColors.accent(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Solde disponible',
                      style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                    Text(
                      '${_controller.solde} FCFA',
                      style: YkTypography.h4(context).copyWith(color: YkColors.accent(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: YkSpacing.md),
              YkTextField(
                controller: _montantCtrl,
                label: 'Montant à retirer',
                hint: 'Ex. 10000',
                type: YkTextFieldType.number,
                required: true,
              ),
              SizedBox(height: YkSpacing.lg),
              YkButton(label: 'Continuer', onPressed: _lancerFlux),
            ],
          );
        },
      ),
    );
  }
}
