// lib/features/paiement/presentation/recharge_page.dart
//
// Écran de recharge du portefeuille (`AppRoute.recharge`, P9.3) — montants
// secs + champ libre, puis `YkManualPaymentFlow(sens: recharge)`. Cible du
// bouton « Recharger mon portefeuille » de `YkWalletDebitConfirmSheet`
// (solde insuffisant) ET du bouton « Recharger » de `wallet_page.dart` —
// un seul écran, pas de duplication (règle 1).

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

import 'recharge_controller.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  late final RechargeController _controller;
  final TextEditingController _montantLibreCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RechargeController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    _montantLibreCtrl.dispose();
    super.dispose();
  }

  void _choisirPreset(int montant) {
    _montantLibreCtrl.clear();
    _controller.choisirMontant(montant);
  }

  Future<void> _lancerFlux() async {
    final montant = _controller.montantChoisi;
    final params = _controller.parametres;
    if (montant == null || montant <= 0 || params == null) return;

    final ok = await YkManualPaymentFlow.show(
      context,
      sens: YkPaiementSens.recharge,
      montant: montant,
      titre: 'Recharge portefeuille',
      ussdOrange: params.ussdOrangeMoney,
      ussdMtn: params.ussdMtnMomo,
      numeroDepotOrange: params.numeroDepotOrange,
      numeroDepotMtn: params.numeroDepotMtn,
      nomAfficheDepot: params.nomAfficheDepot,
      whatsappServiceClient: params.whatsappServiceClient,
      delaiValidationMinutes: params.delaiValidationPaiementMinutes,
      onSoumettre: _controller.soumettre,
      onVerifierStatut: _controller.verifierStatut,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: const Text('Recharge du portefeuille')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.chargementParametres) {
            return Padding(
              padding: EdgeInsets.all(YkSpacing.md),
              child: const YkSkeleton.list(itemCount: 4),
            );
          }
          if (_controller.enErreur) {
            return YkErrorState(
              message: 'Impossible de charger les informations de paiement.',
              cause: 'Vérifiez votre connexion internet.',
              onRetry: _controller.charger,
            );
          }
          return ListView(
            padding: EdgeInsets.all(YkSpacing.md),
            children: [
              Text('Choisissez un montant', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(height: YkSpacing.sm),
              Wrap(
                spacing: YkSpacing.sm,
                runSpacing: YkSpacing.sm,
                children: [
                  for (final montant in montantsRechargeSuggeres)
                    YkChip(
                      label: '$montant FCFA',
                      variant: YkChipVariant.filter,
                      selected: _controller.montantChoisi == montant,
                      onSelected: (_) => _choisirPreset(montant),
                    ),
                ],
              ),
              SizedBox(height: YkSpacing.md),
              YkTextField(
                controller: _montantLibreCtrl,
                label: 'Autre montant',
                hint: 'Ex. 15000',
                type: YkTextFieldType.number,
                onChanged: (v) => _controller.choisirMontant(int.tryParse(v.trim())),
              ),
              SizedBox(height: YkSpacing.lg),
              YkButton(
                label: 'Continuer',
                onPressed: (_controller.montantChoisi ?? 0) > 0 ? _lancerFlux : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
